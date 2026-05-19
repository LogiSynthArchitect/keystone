import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

IconData getLineAwesomeIcon(String iconName) {
  switch (iconName) {
    case 'car':
      return LineAwesomeIcons.car_solid;
    case 'key':
      return LineAwesomeIcons.key_solid;
    case 'tools':
      return LineAwesomeIcons.tools_solid;
    case 'lock':
      return LineAwesomeIcons.lock_solid;
    case 'unlock':
      return LineAwesomeIcons.unlock_solid;
    case 'wrench':
      return LineAwesomeIcons.wrench_solid;
    case 'mobile-alt':
      return LineAwesomeIcons.mobile_alt_solid;
    case 'door-open':
      return LineAwesomeIcons.door_open_solid;
    case 'door-closed':
      return LineAwesomeIcons.door_closed_solid;
    case 'shield-alt':
      return LineAwesomeIcons.shield_alt_solid;
    case 'building':
      return LineAwesomeIcons.building_solid;
    case 'network-wired':
      return LineAwesomeIcons.network_wired_solid;
    case 'id-card':
      return LineAwesomeIcons.id_card_solid;
    case 'video':
      return LineAwesomeIcons.video_solid;
    case 'bell':
      return LineAwesomeIcons.bell_solid;
    case 'envelope':
      return LineAwesomeIcons.envelope_solid;
    case 'archive':
      return LineAwesomeIcons.archive_solid;
    case 'store':
      return LineAwesomeIcons.store_solid;
    case 'gavel':
      return LineAwesomeIcons.gavel_solid;
    case 'motorcycle':
      return LineAwesomeIcons.motorcycle_solid;
    case 'wifi':
      return LineAwesomeIcons.wifi_solid;
    case 'cut':
      return LineAwesomeIcons.cut_solid;
    case 'bolt':
      return LineAwesomeIcons.bolt_solid;
    case 'phone':
      return LineAwesomeIcons.phone_solid;
    default:
      return LineAwesomeIcons.tools_solid;
  }
}
