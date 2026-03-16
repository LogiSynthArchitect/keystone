import 'package:flutter_test/flutter_test.dart';
import 'package:keystone/features/whatsapp_followup/domain/usecases/build_followup_message_usecase.dart';

void main() {
  late BuildFollowupMessageUsecase usecase;

  setUp(() {
    usecase = BuildFollowupMessageUsecase();
  });

  group('BuildFollowupMessageUsecase', () {
    test('builds message containing customer first name', () async {
      // TODO
    });

    test('builds message containing technician name', () async {
      // TODO
    });

    test('builds message containing profile url', () async {
      // TODO
    });

    test('message is at least 10 characters long', () async {
      // TODO
    });
  });
}
