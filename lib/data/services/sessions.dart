

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/subject_model.dart';
import '../models/topic_model.dart';

class Session extends GetxController {
  static Session get instance => Get.find<Session>();


  Map<String,dynamic>? storedData;
  Map<String,dynamic>? currentUser;
  bool isNewTest = false;
  bool isRetest = false;
  SubjectModel? selectedSubject;
  TopicModel? selectedTopic;
  SubtopicModel? selectedSubtopic;
  String? selectedSub;
  String? selectedCategory;
  String currentTestId ='';
  bool isCompletedAssignment = false;
}