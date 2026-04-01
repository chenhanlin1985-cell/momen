# Markdown Story -> Current Project Draft Pack

这份文件不是运行时产物，而是给当前项目使用的桥接草稿包。
目标是把 Markdown 作者稿翻译成当前项目真正维护的三层：CSV / encounter / texts。

## 柳飞霞试探遗物

- markdown_numeric_id: `2101`
- suggested_project_event_id: `friendly_peer_md_2101`
- presentation_type: `standard_event`
- content_category: `npc_state`
- slot: `post_action`
- time_slot: `day`
- primary_npc_id: `friendly_peer`
- location_id: `dormitory`

### Author Summary
description = TODO

### Talk Skeleton
option_01.text = 唤醒旧情
option_01.result = 让她回想起昔日的温存。
option_01.success = (不可能发生的事情)
option_01.failure = 她的眼神深处闪过一丝嘲弄。你感到宿主的经脉开始隐隐作痛。
option_02.text = 引动猜忌
option_02.result = 在她脑海低语：“王麻子已经怀疑你了，他派人盯着这里！”
option_02.success = 她猛地回头，额头渗出冷汗，一把抓住你的衣领低吼：“把东西给我！”
option_02.failure = 她察觉到了你眼神中的异样，冷哼一声退入黑暗。

### CSV Draft
events.csv
friendly_peer_md_2101,<story_id>,<event_class>,npc_state,day,<participants>,,standard_event,friendly_peer,<speaker_visual>,,,post_action,,dormitory,,300,1,false,evt.friendly_peer_md_2101.title,evt.friendly_peer_md_2101.desc,generated_from_markdown,,,,,,,,

event_triggers.csv
friendly_peer_md_2101,main,1,phase_is,,,day,,,
friendly_peer_md_2101,main,2,day_range,,,1-4,,,
friendly_peer_md_2101,main,3,flag_present,,,has_cousin_relic,,,
friendly_peer_md_2101,main,4,npc_tag_present,,,deceiver,friendly_peer,,

event_options.csv
friendly_peer_md_2101_opt_01,friendly_peer_md_2101,1,opt.friendly_peer_md_2101_opt_01.text,opt.friendly_peer_md_2101_opt_01.result,
friendly_peer_md_2101_opt_02,friendly_peer_md_2101,2,opt.friendly_peer_md_2101_opt_02.text,opt.friendly_peer_md_2101_opt_02.result,

option_effects.csv
friendly_peer_md_2101_opt_01,1,modify_resource,player,spirit_sense,-5,,,
friendly_peer_md_2101_opt_01,2,modify_resource,player,blood_qi,-10,,, # outcome=failure
friendly_peer_md_2101_opt_01,3,add_tag,player,poisoned_by_liu,,,, # outcome=failure
friendly_peer_md_2101_opt_02,1,modify_resource,player,spirit_sense,-15,,,
friendly_peer_md_2101_opt_02,2,add_npc_tag,,unstable_ally,,friendly_peer,, # outcome=success
friendly_peer_md_2101_opt_02,3,add_tag,player,knows_truth_wang_murder,,,, # outcome=success
friendly_peer_md_2101_opt_02,4,modify_resource,player,exposure,20,,, # outcome=failure

localization.csv
evt.friendly_peer_md_2101.title,柳飞霞试探遗物
evt.friendly_peer_md_2101.desc,
opt.friendly_peer_md_2101_opt_01.text,唤醒旧情
opt.friendly_peer_md_2101_opt_01.result,让她回想起昔日的温存。
opt.friendly_peer_md_2101_opt_02.text,引动猜忌
opt.friendly_peer_md_2101_opt_02.result,在她脑海低语：“王麻子已经怀疑你了，他派人盯着这里！”

### Encounter/Text Draft
logic.event_id = friendly_peer_md_2101
logic.opening_text_id = friendly_peer_md_2101.opening
logic.observation_text_id = friendly_peer_md_2101.observe
texts.friendly_peer_md_2101.opening = 柳飞霞眼眶红肿，递过一瓶金疮药，指甲缝里隐约有暗红粉末。她柔声问：“你兄长可曾留下什么物件？”
texts.friendly_peer_md_2101.observe = 表层情绪：哀恸、关切。\n环境细节：她递药的手异常苍白，像是提前洗净了血。她的目光明面上落在纸灰和灵位上，余光却一直锁着宿主腰间的储物袋。她真正关心的不是死者，而是那件可能还没被别人先拿走的遗物。
texts.friendly_peer_md_2101.greed.desc = 向她脑海里灌进“只要拿到遗物就能独吞机缘”的幻象，让她的占有欲先一步吞掉谨慎。
texts.friendly_peer_md_2101.greed.hint = 她眼底像是被油光擦亮了一层，连呼吸都变得更快。你能感觉到，她已经开始把宿主也看成挡路的东西。
texts.friendly_peer_md_2101.greed.log = 你把贪念压进了柳飞霞心底最脆弱的缝里。
texts.friendly_peer_md_2101.wrath.desc = 在她心里放大“王麻子已经准备先下手灭口”的恐惧，让她先怀疑共谋者会反咬自己。
texts.friendly_peer_md_2101.wrath.hint = 她的镇定被一点点撕开了。你能感觉到她真正害怕的不是宿主，而是还有另一个人随时会抢先动手。
texts.friendly_peer_md_2101.wrath.log = 你让疑惧和怨恨一起在她心里翻了上来。
texts.friendly_peer_md_2101.delusion.desc = 逼她去回想和族兄的旧日温存，试着从伪装里挤出一点真正的迟疑。
texts.friendly_peer_md_2101.delusion.hint = 她确实短暂晃神了，但那层柔软很快又被压回去。这个人会利用旧情，却不会为旧情付代价。
texts.friendly_peer_md_2101.delusion.log = 你试着把一段旧情埋回她心里，可那道裂缝很快又合上了。
texts.friendly_peer_md_2101.greed.opt_01.text = 顺着她的话继续试探
texts.friendly_peer_md_2101.greed.opt_01.result = 你故意不提玉简，只把话往“值不值得换命”的方向轻轻一拨。
texts.friendly_peer_md_2101.greed.opt_02.text = 直接亮出玉简逼她表态
texts.friendly_peer_md_2101.greed.opt_02.result = 玉简只露出一角，她脸上的伪装便裂开了。浮上来的不是悲伤，而是几乎要立刻动手的贪婪。
texts.friendly_peer_md_2101.wrath.opt_01.text = 追问她是不是已经见过王麻子
texts.friendly_peer_md_2101.wrath.opt_01.result = 她呼吸一滞，像是被你当面揭开了最不敢承认的那层恐惧。
texts.friendly_peer_md_2101.wrath.opt_02.text = 逼她承认王麻子准备灭口
texts.friendly_peer_md_2101.wrath.opt_02.result = 她终于压低声音失控地吐出几个字：“是王麻子要独吞血神阵图！”
notes = 如果这是当前新对话系统要走的事件，请把 Markdown 选项改写成观察/入侵/对话三段结构，再补 intrusion overrides。

### Wiring Reminder
- 请把上面的草稿分发到 csv / encounters / texts
- 运行时只保留当前主结构，不再直接载入 Markdown 产物
- Markdown 在当前项目里只是作者输入层，不再是第二套运行时事件源
