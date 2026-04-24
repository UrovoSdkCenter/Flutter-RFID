import 'package:flutter_test/flutter_test.dart';
import 'package:rfid/rfid.dart';
import 'package:rfid/rfid_platform_interface.dart';
import 'package:rfid/rfid_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockRfidPlatform
    with MockPlatformInterfaceMixin
    implements RfidPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final RfidPlatform initialPlatform = RfidPlatform.instance;

  test('$MethodChannelRfid is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelRfid>());
  });

  test('getPlatformVersion', () async {
    Rfid rfidPlugin = Rfid();
    MockRfidPlatform fakePlatform = MockRfidPlatform();
    RfidPlatform.instance = fakePlatform;

    expect(await rfidPlugin.getPlatformVersion(), '42');
  });
}
