pragma circom 2.0.0;


include "./circomlib/circuits/comparators.circom";
include "./circomlib/circuits/gates.circom";

template Triangle_Validity() {
  
  signal input a[2];
  signal input b[2];
  signal input c[2];

  signal output is_valid;

  signal side_AB;
  signal side_BC;
  signal side_CA;

  signal abx;
  signal aby;
  signal bcx;
  signal bcy;
  signal cax;
  signal cay;

  signal abx2;
  signal aby2;
  signal bcx2;
  signal bcy2;
  signal cax2;
  signal cay2;

  // compute each size of triangles
  
  abx <== a[0] - b[0];
  aby <== a[1] - b[1];
  bcx <== b[0] - c[0];
  bcy <== b[1] - c[1];
  cax <== c[0] - a[0];
  cay <== c[1] - a[1];

  abx2 <== abx * abx;
  aby2 <== aby * aby;
  bcx2 <== bcx * bcx;
  bcy2 <== bcy * bcy;
  cax2 <== cax * cax;
  cay2 <== cay * cay;

  side_AB <== abx2 + aby2;
  side_BC <== bcx2 + bcy2;
  side_CA <== cax2 + cay2;

  // checks if sums of two sides are bigger than another one
  
  component geqt_a = GreaterEqThan(64);
  component geqt_b = GreaterEqThan(64);
  component geqt_c = GreaterEqThan(64);

  geqt_a.in[0] <== side_AB + side_BC; 
  geqt_a.in[1] <== side_CA * side_CA; 

  geqt_b.in[0] <== side_AB + side_CA;
  geqt_b.in[1] <== side_BC * side_BC; 

  geqt_c.in[0] <== side_BC + side_CA; 
  geqt_c.in[1] <== side_AB * side_AB; 

  component multi_and_gate = MultiAND(3);
  multi_and_gate.in[0] <== geqt_a.out;
  multi_and_gate.in[1] <== geqt_b.out;
  multi_and_gate.in[2] <== geqt_c.out;

  is_valid <== multi_and_gate.out;
}

template Distance_Points() {

  signal input a[2];
  signal input b[2];

  signal output distance;

  signal delta_x;
  signal delta_y;

  signal delta_x2;
  signal delta_y2;

  delta_x <== a[0] - b[0];
  delta_y <== a[1] - b[1];

  delta_x2 <== delta_x * delta_x;
  delta_y2 <== delta_y * delta_y;


  distance <== delta_x2 + delta_y2;
  
}

template Player_Energy() {

  signal input energy;
  signal input a[2];
  signal input b[2];

  signal output is_enough;

  // calculate distance between two points
  
  component distance_between_points = Distance_Points();
  distance_between_points.a[0] <== a[0];
  distance_between_points.a[1] <== a[1];
  distance_between_points.b[0] <== b[0];
  distance_between_points.b[1] <== b[1];

  // 
  
  component distanceComparator = LessEqThan(32);
  distanceComparator.in[0] <== energy * energy;
  distanceComparator.in[1] <== distance_between_points.distance;

  is_enough <== distanceComparator.out;
}

template Triangle_Jump() {
  signal input energy;
  signal input a[2];
  signal input b[2];
  signal input c[2];
  
  signal output out;

  // compute if has enough energy to distance
  
  component AB_has_energy = Player_Energy();
  component BC_has_energy = Player_Energy();

  AB_has_energy.energy <== energy;
  AB_has_energy.a[0] <== a[0];
  AB_has_energy.a[1] <== a[1];
  AB_has_energy.b[0] <== b[0];
  AB_has_energy.b[1] <== b[1];

  BC_has_energy.energy <== energy;
  BC_has_energy.a[0] <== b[0];
  BC_has_energy.a[1] <== b[1];
  BC_has_energy.b[0] <== c[0];
  BC_has_energy.b[1] <== c[1];

  // check if coordinates froms a valid triangle
  
  component is_valid_triangle = Triangle_Validity();
  is_valid_triangle.a[0] <== a[0];
  is_valid_triangle.a[1] <== a[1];
  is_valid_triangle.b[0] <== b[0];
  is_valid_triangle.b[1] <== b[1];
  is_valid_triangle.c[0] <== c[0];
  is_valid_triangle.c[1] <== c[1];

  component multi_and_gate = MultiAND(3);
  multi_and_gate.in[0] <== AB_has_energy.is_enough;
  multi_and_gate.in[1] <== AB_has_energy.is_enough;
  multi_and_gate.in[2] <== is_valid_triangle.is_valid;

  out <== multi_and_gate.out; 
}

component main = Triangle_Jump(); 
