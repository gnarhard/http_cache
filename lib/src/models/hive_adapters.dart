import 'package:http_cache/src/models/post.dart';
import 'package:hive_ce/hive_ce.dart';

@GenerateAdapters([AdapterSpec<Post>()])
part 'hive_adapters.g.dart';
