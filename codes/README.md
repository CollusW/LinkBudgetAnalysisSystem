# LinkSimulation_MATLAB_V5_1_localXYZ_FULL

通信链路仿真与天线约束分析系统 V5.1 localXYZ 工程版。

## 核心原则

1. 核心链路仿真只使用 local XYZ 坐标。
2. Tx/Rx 距离必须由坐标计算，不允许输入 `d`、`distance`、`range` 等字段。
3. GPS/WGS84 只作为 `tools/gps_to_local_xyz/` 中的可选预处理工具，不进入核心链路预算内核。
4. TOP 层只调用模块，不写核心逻辑。

## 坐标定义

local XYZ：

- X：前方
- Y：右侧
- Z：向上
- 单位：m

视线角度：

- `Az = atan2(y, x)`
- `El = atan2(z, sqrt(x^2+y^2))`

## 主入口

```matlab
main_link_top
```

## 推荐测试顺序

```matlab
tests/test_01_omni_static_xyz.m
tests/test_02_omni_distance_xyz.m
tests/test_06_realistic_local_xyz_scenario.m
```

其中 TC06 是准实际 local XYZ 地空链路场景，比固定距离测试更能说明工程问题。

## 目录结构

```text
LinkSimulation_MATLAB_V5_1_localXYZ_FULL/
├── main_link_top.m
├── config/
├── io/
├── core/
│   ├── geometry/
│   ├── antenna/
│   └── linkbudget/
├── plot/
├── input/
├── output/
├── tests/
├── tools/gps_to_local_xyz/
└── docs/
```

## 输出

默认输出到：

```text
output/link_result.csv
output/link_result.mat
output/figures/
```

## 重要说明

如果使用 CSV 输入，轨迹文件只能包含：

```text
t,x,y,z,yaw,pitch,roll
```

不能包含距离字段。距离统一由：

```matlab
d = norm(rx_xyz - tx_xyz)
```

计算得到。
