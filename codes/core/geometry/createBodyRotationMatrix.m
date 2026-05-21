function R = createBodyRotationMatrix(yaw_deg, pitch_deg, roll_deg)
% createBodyRotationMatrix
% 生成 Body -> local XYZ 的旋转矩阵。
%
% local XYZ：X 前方，Y 右侧，Z 向上。
% 欧拉角顺序：R = Rz(yaw) * Ry(pitch) * Rx(roll)。
% local -> Body 使用 R'。

cy = cosd(yaw_deg);  sy = sind(yaw_deg);
cp = cosd(pitch_deg); sp = sind(pitch_deg);
cr = cosd(roll_deg); sr = sind(roll_deg);

Rz = [ cy, -sy, 0;
       sy,  cy, 0;
        0,   0, 1];

Ry = [ cp, 0, sp;
        0, 1,  0;
      -sp, 0, cp];

Rx = [1,  0,   0;
      0, cr, -sr;
      0, sr,  cr];

R = Rz * Ry * Rx;
end
