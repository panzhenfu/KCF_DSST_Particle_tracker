function [ St ] = particle_propagate( St,N,V )
%PARTICLE_PROPAGATE particle_propagate:St = ASt_1 + W
%   St:状态集合
%   N :粒子数
%   V :运动速度
%   panzhenfu 华北电力大学 2016.1
POSITION_DISTURB = 0.000;%位置扰动幅度
VELOCITY_DISTURB = 0.00125;%速度扰动幅度
eta = 0.00125;
for i = 1:N,
        R = normrnd(0,1,4,1); %产生4×1的标准正态分布矩阵
     St(i).vx = R(3)*V(1)*eta + R(3)*VELOCITY_DISTURB; 
    St(i).vy = R(4)*V(2)*eta+ R(4)*VELOCITY_DISTURB;
    St(i).pos(1) = St(i).pos(1) + St(i).vx + R(1)*POSITION_DISTURB;
    St(i).pos(2) = St(i).pos(2) +  St(i).vy + R(2)*POSITION_DISTURB;
    St(i).psr = 0.0;
    St(i).weight = 0.0;
end


end

