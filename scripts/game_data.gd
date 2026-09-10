class_name GameData
extends RefCounted

const W := 1280.0
const H := 720.0
const BOARD_X := 165.0
const BOARD_Y := 150.0
const CELL_W := 120.0
const CELL_H := 110.0
const ROWS := 5
const COLS := 9
const ZOMBIE_DPS := 100.0
const SUNFLOWER_INTERVAL := 16.0

const ITEM_DATA := {
	"air_bomb": {"name":"空投炸弹", "price":8000, "max_owned":3, "hotkey":KEY_A,
		"summary":"选择草坪落点，造成樱桃炸弹的范围伤害。"},
	"sun_pack": {"name":"阳光礼包", "price":6000, "max_owned":99, "hotkey":KEY_S,
		"summary":"在关卡中立即补充500阳光。"}
}

const ZOMBIE_POINTS := {
	"normal": 1,
	"cone": 2,
	"bucket": 3,
	"runner": 3,
	"kart": 4,
	"swing": 2,
	"charger": 4
}

const PLANT_DATA := {
	"sunflower": {"name":"向日葵", "cost":50, "cool":5.0, "hp":300.0, "damage":0.0, "interval":0.0, "color":Color("#ffd84a")},
	"pea": {"name":"豌豆射手", "cost":100, "cool":6.0, "hp":300.0, "damage":20.0, "interval":1.42, "color":Color("#70cf45")},
	"wall": {"name":"坚果墙", "cost":50, "cool":12.0, "hp":4000.0, "damage":0.0, "interval":0.0, "color":Color("#b97942")},
	"mine": {"name":"土豆地雷", "cost":25, "cool":6.0, "hp":300.0, "damage":1800.0, "interval":0.0, "arm_time":14.0, "color":Color("#b88148")},
	"snow": {"name":"寒冰射手", "cost":175, "cool":9.0, "hp":300.0, "damage":25.0, "interval":1.85, "color":Color("#76dceb")},
	"cherry": {"name":"樱桃炸弹", "cost":150, "cool":30.0, "hp":300.0, "damage":1800.0, "interval":0.72, "color":Color("#ef4b45")},
	"yam_guard": {"name":"红薯防卫队", "cost":125, "cool":15.0, "hp":300.0, "damage":60.0, "interval":0.0, "respawn":8.0, "heal":25.0, "color":Color("#c85f3d")},
	"needle": {"name":"鬼针草射手", "cost":125, "cool":7.5, "hp":300.0, "damage":20.0, "interval":0.65, "column_radius":2, "color":Color("#a85ac7")},
	"cactus": {"name":"仙人掌", "cost":175, "cool":7.5, "hp":300.0, "damage":20.0, "interval":1.42, "max_targets":3, "color":Color("#58aa55")},
	"slime": {"name":"粘液多肉", "cost":75, "cool":15.0, "hp":300.0, "damage":20.0, "interval":1.7, "column_radius":1, "color":Color("#65b89a")},
	"squash": {"name":"倭瓜", "cost":50, "cool":30.0, "hp":300.0, "damage":1800.0, "interval":0.0, "color":Color("#78a957")}
}

const PLANT_INFO := {
	"sunflower": {"role":"资源生产", "summary":"周期性生产阳光，是建立防线经济的核心。", "tip":"尽早种植在后排，并用坚果墙保护。"},
	"pea": {"role":"单线输出", "summary":"向所在行发射豌豆，持续攻击前方的僵尸。", "tip":"适合成排布置，稳定处理普通僵尸。"},
	"wall": {"role":"前排防御", "summary":"拥有很高的生命值，可以长时间阻挡僵尸。", "tip":"放在输出植物前方，为攻击争取时间。"},
	"mine": {"role":"埋伏爆破", "summary":"种下后需要准备，成熟时会炸毁靠近的僵尸。", "tip":"提前种在僵尸行进路线上，适合低成本处理重甲敌人。"},
	"snow": {"role":"减速输出", "summary":"寒冰子弹会降低僵尸移动速度并造成伤害。", "tip":"每行一株即可显著延长整条防线的输出时间。"},
	"cherry": {"role":"范围爆发", "summary":"短暂延迟后爆炸，重创附近三行内的僵尸。", "tip":"适合处理密集尸群或紧急解围。"},
	"yam_guard": {"role":"跨行驻守", "summary":"向相邻黄土地块派出小红薯驻守；空闲时会回血，阵亡后会自动补充。", "tip":"种在第3行时，点击防卫队本体可切换上方或下方的驻守格。"},
	"needle": {"role":"邻线速射", "summary":"快速攻击上下相邻行五格范围内最靠近房子的僵尸。", "tip":"放在中间行可以同时照顾两条相邻路线，但不会攻击自身所在行。"},
	"cactus": {"role":"直线穿透", "summary":"以豌豆射手相同的频率发射尖刺，每发最多贯穿所在行的三个僵尸。", "tip":"面对排成一列的尸群时效率很高，适合布置在防线后方。"},
	"slime": {"role":"近距控制", "summary":"固定同一行自身格及前后一格内的一只僵尸，并持续造成伤害，攻击稍慢于豌豆射手。", "tip":"被固定的僵尸无法移动或啃咬；卡丁车车体不受固定影响。"},
	"squash": {"role":"近距爆发", "summary":"发现同一行前后约一格内的僵尸后跃起砸向目标，对落点附近的僵尸造成1800伤害，随后消失。", "tip":"适合低成本应急，也能一次压住挤在一起的多个敌人。"}
}

const ZOMBIE_INFO := {
	"normal": {"name":"普通僵尸", "role":"基础敌人", "hp":190, "speed":15, "summary":"行动缓慢、耐久一般，是最常见的进攻单位。", "tip":"一株持续输出植物通常可以从容应对。"},
	"cone": {"name":"路障僵尸", "role":"强化敌人", "hp":560, "speed":15, "summary":"头顶路障提供额外防护，比普通僵尸更耐打。", "tip":"集中火力，或用寒冰射手拖延它的推进。"},
	"bucket": {"name":"铁桶僵尸", "role":"重甲敌人", "hp":1290, "speed":15, "summary":"铁桶带来极高防护，能够承受大量远程攻击。", "tip":"利用坚果拖延，并准备樱桃炸弹快速清除。"},
	"runner": {"name":"疾跑僵尸", "role":"快速敌人", "hp":160, "speed":35, "summary":"生命较低但移动迅速，容易突破尚未成形的防线。", "tip":"及时补齐空行，寒冰减速对它尤其有效。"},
	"flag": {"name":"旗帜僵尸", "role":"大波先锋", "hp":190, "speed":15, "summary":"挥舞旗帜走在尸群前方，宣告一大波僵尸来袭。", "tip":"旗帜出现时应立即检查每一行的防线。"},
	"kart": {"name":"卡丁车小鬼僵尸", "role":"载具敌人", "hp":500, "speed":20, "summary":"驾驶卡丁车碾压植物；车体被击毁后，小鬼会下车继续前进。", "tip":"在卡丁车接近前集中火力，避免它连续碾过植物。"},
	"swing": {"name":"摇摆僵尸", "role":"换行敌人", "hp":300, "speed":17, "summary":"每隔一段时间随机移动到相邻行，绕开单行布置的防线。", "tip":"用多行火力覆盖它，粘液多肉可以阻止其换行。"},
	"charger": {"name":"钢盔冲锋僵尸", "role":"高速重甲", "hp":1690, "armor":1500, "speed":25, "summary":"钢盔提供1500点防护，脱落后剩余190点本体生命。", "tip":"先用爆发打掉钢盔，再以持续火力解决本体。"}
}

const LEVEL_DATA := {
	1: {"world":"前院", "stage":1, "waves":10, "plants":["sunflower","pea","wall","mine"], "reward":"cherry"},
	2: {"world":"前院", "stage":2, "waves":10, "plants":["sunflower","pea","wall","mine","cherry"], "reward":"snow"},
	3: {"world":"前院", "stage":3, "waves":10, "plants":["sunflower","pea","wall","mine","cherry","snow"], "reward":"yam_guard"},
	4: {"world":"荒地", "stage":1, "waves":10, "plants":["sunflower","pea","wall","mine","cherry","snow","yam_guard"], "reward":"needle"},
	5: {"world":"荒地", "stage":2, "waves":20, "plants":["sunflower","pea","wall","mine","cherry","snow","yam_guard","needle"], "reward":"cactus"},
	6: {"world":"荒地", "stage":3, "waves":10, "plants":["sunflower","pea","wall","mine","cherry","snow","yam_guard","needle","cactus"], "reward":"slime"},
	7: {"world":"荒地", "stage":4, "waves":10, "plants":["sunflower","pea","wall","mine","cherry","snow","yam_guard","needle","cactus","slime"], "reward":"money_bag"},
	8: {"world":"荒地", "stage":5, "waves":20, "plants":["sunflower","pea","wall","mine","cherry","snow","yam_guard","needle","cactus","slime"], "reward":"squash"},
	9: {"world":"荒地", "stage":6, "waves":30, "plants":["sunflower","pea","wall","mine","cherry","snow","yam_guard","needle","cactus","slime","squash"], "reward":""},
	10: {"world":"荒地", "stage":7, "waves":20, "plants":["sunflower","pea","wall","mine","cherry","snow","yam_guard","needle","cactus","slime","squash"], "reward":""},
	11: {"world":"荒地", "stage":8, "map":"frontyard", "waves":10, "plants":["sunflower","slime"], "reward":"", "fixed_loadout":true, "wave_interval_scale":1.5}
}
