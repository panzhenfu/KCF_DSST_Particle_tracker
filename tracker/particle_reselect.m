function [ St ] = particle_reselect( St_1,N )
%PARTICLE_RESELECT the particle important reselect
%权值归一化
%潘振福 华北电力大学 2016
sumpsr = 0;
for i = 1:N,
    sumpsr = sumpsr + St_1(i).psr;
end
for i = 1:N,
    St_1(i).weight = St_1(i).psr/sumpsr;
end
%   权重累计
cumulateweight(1) = 0;
for i = 1:N,
   cumulateweight(i+1) = cumulateweight(i) + St_1(i).weight;
end
for i = 1:N+1,
    cumulateweight(i) = cumulateweight(i)/cumulateweight(N+1); 
end
   for i = 1:N,
       rum = rand;%随机产生一个[0,1]之间均匀分布的数
       %二分查找
       l = 0;r = N;
       while r>=l
           m = floor((l + r) / 2);
           if (rum >= cumulateweight(m)&& rum<cumulateweight(m+1)),
               break;
           end
           if rum<cumulateweight(m),
              r=m-1;
           else
                l = m+1;
           end
       end
       resampleIndex(i) = m;
   end
    for i = 1:N,
        St(i) = St_1( resampleIndex(i));
    end
end

