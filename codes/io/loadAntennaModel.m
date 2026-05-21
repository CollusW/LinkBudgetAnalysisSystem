function Ant = loadAntennaModel(sideCfg, AntCfg, sideName)
% loadAntennaModel
% 加载 Tx 或 Rx 天线模型。

Ant = struct();
Ant.name = sideName;
Ant.type = lower(sideCfg.type);
Ant.interpolation = AntCfg.interpolation;
Ant.outOfBound = AntCfg.outOfBound;
Ant.angleInputType = AntCfg.angleInputType;

switch Ant.type
    case 'omni'
        Ant.omni_gain_dbi = sideCfg.omni_gain_dbi;
        Ant.Az_grid = [];
        Ant.El_grid = [];
        Ant.Gain_grid = [];

    case 'pattern'
        switch lower(sideCfg.patternSource)
            case 'synthetic'
                [Ant.Az_grid, Ant.El_grid, Ant.Gain_grid] = createSyntheticAntennaPattern(sideName);
            case 'csv'
                [Ant.Az_grid, Ant.El_grid, Ant.Gain_grid] = loadAntennaPatternCsv(sideCfg.patternFile, AntCfg.angleInputType);
            otherwise
                error('%s 天线 patternSource 未知：%s', sideName, sideCfg.patternSource);
        end
        Ant.omni_gain_dbi = NaN;

    otherwise
        error('%s 天线类型未知：%s', sideName, sideCfg.type);
end
end
