data {
    matrix[2, 3] X_1;
    array[2, 3] real X_2;
    array[2, 3, 4] real X_3;
    array[3] int y;
}

parameters {
    real theta;    
}

model {
    theta ~ std_normal();
}

generated quantities {
    matrix[2, 3] X_1_;
    array[2, 3] real X_2_;
    array[2, 3, 4] real X_3_;
    array[3] int y_;
 
    X_1_ = X_1;
    X_2_ = X_2;
    X_3_ = X_3;
    y_ = y;
}
