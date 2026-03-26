export_material = 0; 

// Building Definitions
r1_points = [[-130, 178.5], [-57, 178.5], [15, -156.5], [-130, -156.5]];
r1_h = 1313.35; r1_twist = 29; r1_x_lean = 20; r1_y_lean = -20;

r2_points = [[-17, 157.5], [129, 157.5], [129, -177.5], [55, -177.5]];
r2_h = 1336; r2_twist = 29; r2_x_lean = -20; r2_y_lean = 20;

r3_points = [[-94, 105.25], [43, 134.25], [94, -102.25], [-43, -134.25]];
r3_h = 1290.71; r3_twist = 29; r3_x_lean = 0; r3_y_lean = 0;

// Pillar Coordinate Groups (Material 6)
group_4_coords = [[-122.5, 158.0], [-122.5, 104.0], [-122.5, 50.0], [-122.5, -4.0], [-122.5, -59.0], [-122.5, -113.0], [-111.5, -152.0], [-56.5, -152.0], [-2.5, -152.0], [-74.5, 170.0], [-85.5, 113.0], [-48.5, 106.0], [0.5, -120.0]];

group_5_coords = [[2.5, 149.0], [-0.5, 116.0], [48.5, -109.0], [75.5, -171.0], [56.5, 149.0], [111.5, 149.0], [122.5, 110.0], [122.5, 56.0], [122.5, 1.0], [122.5, -53.0], [122.5, -107.0], [96.5, -119.0], [122.5, -160.0]];

// Core Shape and Door Data
core_pts = [[54, 102.5], [93, -69.5], [-55, -102.5], [-94, 69.5]];
core_wall_thickness = 4.5;
door_pts = [
    [[-28, 83.5], [-12, 87.5]], [[11, -88.5], [27, -84.5]],
    [[-88, 47.5], [-85, 31.5]], [[60, 80.5], [63, 64.5]],
    [[-63, -65.5], [-60, -81.5]], [[85, -32.5], [88, -38.5]]
];

global_scaling = 0.99;
window_target_width = 9; 
mullion_w = 1.2;          
mullion_d = 2.0;          

module sarona_facade(pts, h, tw, xl, yl, pillar_pts=[], s_start=0.5, s_final=0.95, floor_count=59, outer_res=590) {
    inner_slices = floor_count; 
    outer_slices = outer_res; // Updated to use the passed parameter
    inward_lean = 2.5; 

    scale([global_scaling, global_scaling, 1])
    multmatrix(m = [[1, 0, xl/h, 0], [0, 1, yl/h, 0], [0, 0, 1, 0], [0, 0, 0, 1]]) {
        
        // INNER STRUCTURE (Floors & Pillars)
        if (export_material == 0 || export_material == 1 || export_material == 2 || export_material == 3 || export_material == 6) {
            for (i = [0 : inner_slices - 1]) {
                let (
                    progress = i / inner_slices,
                    curr_h = i * (h / inner_slices),
                    angle = progress * tw,
                    s = (progress < s_start) ? 1.0 : 1.0 - ((progress - s_start) / (1 - s_start) * (1.0 - s_final))
                ) {
                    translate([0, 0, curr_h]) rotate([0, 0, angle]) scale([s, s, 1]) {
                        
                        // MATERIAL 1: FLOORS
                        if (export_material == 0 || export_material == 1) {
                            color([0.5, 0.5, 0.5]) linear_extrude(height = 1.4) polygon(points = pts);
                            translate([0, 0, (h / inner_slices) - 1.4]) 
                                color([0.5, 0.5, 0.5]) linear_extrude(height = 1.4) polygon(points = pts);
                        }

                        // MATERIAL 6: PILLARS
                        if (export_material == 0 || export_material == 6) {
                            for (p_pos = pillar_pts) {
                                translate([p_pos[0], p_pos[1], 0])
                                    color([0.8, 0.8, 0.8]) cylinder(d=7, h=(h/inner_slices), $fn=32);
                            }
                        }

                        // FACADE LOGIC
                        for (p = [0 : len(pts)-1]) {
                            let (p1 = pts[p], p2 = pts[(p + 1) % len(pts)],
                                 edge_vec = p2 - p1, edge_len = norm(edge_vec),
                                 edge_angle = atan2(edge_vec[1], edge_vec[0]),
                                 win_count = round(edge_len / window_target_width),
                                 actual_win_w = edge_len / win_count)
                            for (w = [0 : win_count - 1]) {
                                let (w_offset = w * actual_win_w, pos = p1 + (edge_vec * (w_offset / edge_len))) {
                                    translate([pos[0], pos[1], 1.5]) rotate([0, 0, edge_angle]) rotate([inward_lean, 0, 0]) {
                                        if (export_material == 0 || export_material == 2)
                                            color([0.9, 0.9, 0.9]) cube([mullion_w, mullion_d, (h/inner_slices) - 1.3]);
                                        
                                        if (export_material == 0 || export_material == 3)
                                            color([0.7, 0.7, 0.7, 0.5]) translate([mullion_w, 0.5, 0])
                                            cube([actual_win_w - mullion_w, 0.5, (h/inner_slices) - 1.3]);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

      // OUTER SHELL (Glass Skin)
        if (export_material == 0 || export_material == 4 || export_material == 5) {
            for (j = [0 : outer_slices - 1]) {
                let (
                    progress = j / outer_slices,
                    curr_h = j * (h / outer_slices),
                    angle = progress * tw,
                    s = (progress < s_start) ? 1.0 : 1.0 - ((progress - s_start) / (1 - s_start) * (1.0 - s_final))
                ) {
                    translate([0, 0, curr_h]) rotate([0, 0, angle]) {
                        for (p = [0 : len(pts)-1]) {
                            let (p1 = pts[p] * s, p2 = pts[(p+1)%len(pts)] * s, 
                                 edge_vec = p2-p1, edge_len = norm(edge_vec), 
                                 edge_angle = atan2(edge_vec[1], edge_vec[0]),
                                 win_count = round(norm(pts[(p+1)%len(pts)] - pts[p]) / window_target_width),
                                 actual_win_w = edge_len / win_count) {
                                
                                translate([p1[0], p1[1], 0]) rotate([0, 0, edge_angle]) {
                                    if (export_material == 0 || export_material == 4) {
                                        rotate([inward_lean, 0, 0]) {
                                            color([0.77, 0.77, 0.81, 0.35]) 
                                            translate([-3.0, mullion_d, 0]) 
                                            cube([edge_len + 6.0, 0.4, (h/outer_slices) + 0.2]); 
                                        }
                                    }
                                    
                                    if (export_material == 0 || export_material == 5) {
                                        for (w = [0 : win_count]) {
                                            let(line_x = w * actual_win_w)
                                            translate([line_x - 0.1, mullion_d + 0.41, 0])
                                            color([0.2, 0.2, 0.2])
                                            cube([0.25, 0.05, (h/outer_slices)]); 
                                        }

                                        if ((j * inner_slices) % outer_slices < inner_slices) {
                                            translate([0, mullion_d + 0.415, 0]) 
                                            color([0.2, 0.2, 0.2])
                                            cube([edge_len, 0.05, 0.25]); 
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
module building_core(h, slices) {
    if (export_material == 0 || export_material == 7) {
        color([0.8, 0.8, 0.8]) {
            // Build the core using 4 solid cubes (walls)
            for (p = [0 : len(core_pts) - 1]) {
                let (
                    p1 = core_pts[p], 
                    p2 = core_pts[(p + 1) % len(core_pts)],
                    edge_vec = p2 - p1,
                    edge_len = norm(edge_vec),
                    edge_ang = atan2(edge_vec[1], edge_vec[0])
                ) {
                    // Each wall is a separate 3D cube
                    translate([p1[0], p1[1], 0]) 
                    rotate([0, 0, edge_ang]) 
                    difference() {
                        // The Wall Slab (Exactly 4.5 thickness)
                        cube([edge_len, 4.5, h]);

                        // Subtract Doors from this specific wall cube
                        for (i = [0 : slices - 1]) {
                            let(floor_z = i * (h / slices))
                            translate([edge_len / 2, 2.25, floor_z + 11.5]) // Center of wall
                            cube([15, 5, 20], center=true); // Standard door cut
                        }
                    }
                }
            }
        }
    }
}
export_mode = 6; 

render_group(export_mode);

module render_group(id) {
    export_material = id; 
    
    building_core(1290.71, 57);
  // r1: 58 floors, 580 outer slices
    sarona_facade(r1_points, r1_h, r1_twist, r1_x_lean, r1_y_lean, group_4_coords, 0.5, 0.95, 58, 580);
    
    // r2: 59 floors, 590 outer slices
    sarona_facade(r2_points, r2_h, r2_twist, r2_x_lean, r2_y_lean, group_5_coords, 0.5, 0.95, 59, 590);
    
    // r3: 57 floors, 570 outer slices
    sarona_facade(r3_points, r3_h, r3_twist, r3_x_lean, r3_y_lean, [], 0.5, 0.95, 57, 570);
}
