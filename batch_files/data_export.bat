sqlcmd -S GEARSERVER\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job_Operation] ,[Employee] ,[Work_Date] ,[Act_Setup_Hrs] ,[Act_Run_Hrs] ,[Act_Run_Qty] ,[Act_Scrap_Qty] ,[Note_Text] FROM [PRODUCTION].[dbo].[Job_Operation_Time] WHERE Job_Operation in (779150, 779149, 779148, 779147, 779146, 779145, 779144, 779143, 779142, 779141, 779140, 779139, 779138, 780901, 780900, 780899, 780898, 780897, 780896, 780895, 780894, 780893, 780892, 780891, 780890, 780889, 780888, 780887, 780886, 780885, 780884, 780883, 780882, 780881, 780880, 780879, 780878, 780877, 780876, 780857, 780856, 780855, 780854, 780853, 780852, 780851, 780850, 780849, 780848, 780847, 780846, 780845, 780844, 780843, 780842, 780841, 780840, 780839, 780838, 780837, 780836, 780827, 780826, 780825, 780824, 780823, 780822, 780821, 780779, 780778, 780777, 780776, 780775, 780774, 780773, 780772, 780771, 780770, 780769, 780768, 780767, 780766, 780765, 780764, 780763, 780762, 780761, 780760, 780875, 780874, 780873, 780872, 780871, 780870, 780869, 780868, 780867, 780866, 780865, 780759, 780758, 780757, 780756, 780755, 780754, 780753, 780752, 780751, 780750, 780749, 780748, 780747, 780746, 780745, 780744, 780743, 780742, 780741, 780740, 780739, 780738, 780737, 780736, 780735, 780734, 780733, 780732, 780731, 780730, 780729, 780728, 780727, 780726, 780715, 780714, 780713, 780835, 780711, 780710, 780709, 780820, 780708, 780707, 780706, 780705, 780704, 780703, 780702, 780701, 780700, 780679, 780678, 780677, 780676, 780675, 780674, 780673, 780672, 780671, 780670, 780565, 780564, 780563, 780562, 780561, 780560, 780559, 780558, 780557, 780554, 780556, 780544, 780543, 780542, 780541, 780540, 780539, 780538, 780537, 780389, 780388, 780387, 780386, 780385, 780384, 780383, 780382, 780381, 780380, 780280, 780279, 780278, 780277, 780276, 780275, 780274, 780273, 780198, 780197, 780196, 780195, 780194, 780193, 780192, 780070, 780069, 780068, 780067, 780066, 780065, 780064, 780239, 780062, 780061, 780041, 780040, 780039, 780038, 780037, 780036, 780035, 780034, 780033, 780032, 780031, 780030, 780001, 780000, 779999, 779998, 779997, 780008, 779996, 779823, 779822, 779821, 779820, 779819, 779818, 779817, 779816, 779669, 779668, 779667, 779666, 779665, 779664, 779663, 779690, 779689, 779688, 779687, 779686, 779685, 779713, 779712, 779711, 779710, 779709, 779708, 779707, 779706, 779705, 779703, 779614, 779613, 779612, 779611, 779610, 779609, 779608, 779607, 779606, 779702, 779770, 779701, 779700, 779699, 779694, 779693, 779698, 779697, 779696, 779695, 779692, 779691, 779448, 779447, 779446, 779445, 779444, 779443, 779442, 779441, 779440, 779303, 779312, 779311, 779310, 779309, 779308, 779307, 779306, 779305, 779304, 779302, 779517, 779516, 779515, 779514, 779513, 779512, 779511, 779518, 779240, 779239, 779329, 779236, 779235, 779234, 779233, 779232, 779231, 779230, 779200, 779199, 779198, 779197, 779196, 779195, 779194, 779193, 779192, 779191, 779190, 779189, 779188, 779187, 779186, 779185, 779184, 779113, 779112, 779111, 779110, 779109, 779108, 779107, 779106, 779105, 779104, 779043, 779042, 779041, 779040, 779039, 779029, 779028, 779027, 779026, 779025, 779024, 779023, 779022, 779002, 779001, 779000, 778999, 778998, 778997, 778996, 778995, 778994, 778993, 778992, 778991, 778989, 778988, 778987, 778986, 778985, 780483, 778984, 778983, 778982, 778981, 778941, 778935, 778934, 778940, 778939, 778932, 778931, 778933, 778938, 778937, 778936, 778930, 778694, 778627, 778626, 778625, 778624, 778623, 778622, 778621, 778620, 778619, 778618, 778617, 778616, 778615, 778568, 778567, 778566, 778565, 778564, 778563, 778562, 778561, 778360, 778359, 778358, 778357, 778356, 778355, 778354, 778353, 778292, 778291, 778290, 778288, 778287, 778286, 778285, 778284, 778283, 778282, 778247, 778246, 778245, 778244, 778243, 778242, 778241, 778240, 778239, 778058, 778057, 778056, 778055, 778054, 778053, 778052, 778051, 778050, 778049, 778048, 777889, 777888, 777887, 777886, 777885, 777884, 777883, 777882, 777881, 777880, 777879, 777818, 777817, 777816, 777815, 777814, 777813, 777812, 777811, 777810, 777471, 777470, 777469, 777468, 777467, 777466, 777465, 777464, 777463, 777462, 777461, 777460, 777459, 777458, 777457, 777456, 777455, 777454, 777453, 777452, 777451, 777450, 777449, 777448, 777447, 777446, 777445, 777351, 777350, 777349, 777348, 777347, 777346, 777345, 777133, 777132, 777131, 777130, 777129, 777128, 777127, 777018, 777017, 777016, 777015, 777014, 777013, 777012, 777011, 777010, 777009, 776907, 776906, 776905, 776904, 776903, 776902, 776901, 776900, 776899, 776737, 776736, 776735, 776734, 776733, 776732, 776474, 776473, 776472, 776471, 776470, 776468, 776467, 776466, 776210, 776209, 776208, 776207, 776206, 776205, 775867, 775866, 775865, 775864, 775863, 775862, 775861, 775860, 775859, 775858, 775857, 775856, 775855, 775854, 775853, 775852, 775851, 775709, 775708, 775707, 775706, 775705, 775704, 775703, 775702, 775701, 775700, 775699, 775698, 775697, 775696, 775695, 775694, 775693, 775692, 775691, 775690, 775689, 775519, 775518, 775517, 775516, 775515, 775514, 775513, 775512, 775511, 774615, 774614, 774613, 774612, 774611, 774610, 774609, 774608, 774027, 774026, 774025, 774024, 774023, 774022, 774021, 774020, 774019, 774018, 772985, 772984, 772983, 772982, 772981, 772980, 772979, 772978, 772977, 772976, 772975, 772974, 759624, 759626, 759625, 759623) ORDER BY Job_Operation DESC" -o "c:/phoenixapps/shophawk_2.0/csv_files/operationtime.csv" -W -w 1024 -s "`" -f 65001 -h -1
