# 军迷僵尸（camo）

迷彩帽、迷彩服、护肘、军靴与匍匐轮廓；面孔沿用已确认的圆脸、无耳朵、皱纹和正视瞳孔。

13 个独立 SVG 部件包含断臂袖口。共享 360 × 190 透明画布，锚点 (155,100)，游戏比例 0.45；不能分别裁去透明边界。source.json 保存源片段，zombie.svg 是完整静态造型。

scripts/camo_art.gd 控制爬行、轻微待机呼吸、啃咬下颌及断臂显示。rooted 状态会停止爬行动作。绘制时保留并恢复父级变换，兼容选卡摄像机。

视觉检查入口：tools/check_camo_art.tscn。机制回归：Godot --headless --path . --quit-after 90 -- --smoke-camo。数值、低位受击和关卡配置沿用现有实现。
