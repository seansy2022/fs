import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _warningLightSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="72" height="72" viewBox="0 0 72 72" fill="none"><g filter="url(#filter_1_1188)"><circle cx="36" cy="36" r="36" fill="#1B2D4D" fill-opacity="0.4"></circle><circle cx="36" cy="36" r="36" fill="url(#linear_fill_1_1188_1)"></circle><path fill-rule="evenodd" fill="rgba(0, 198, 255, 1)" d="M36 72C55.8823 72 72 55.8823 72 36C72 16.1177 55.8823 0 36 0C16.1177 0 0 16.1177 0 36C0 55.8823 16.1177 72 36 72ZM36 2C54.7777 2 70 17.2223 70 36C70 54.7777 54.7777 70 36 70C17.2223 70 2 54.7777 2 36C2 17.2223 17.2223 2 36 2Z"></path></g><path fill-rule="evenodd" d="M15.0971 51.9739C14.1045 52.1453 13 51.4642 13 50.2531L13 50.2298C13 49.838 13.131 49.4766 13.3522 49.1855L34.7281 12.8687C35.4139 11.7035 37.1237 11.7122 37.7974 12.8843L58.7675 49.3701C59.4358 50.5326 58.584 51.9739 57.2284 51.9739L15.0971 51.9739ZM17.8548 48.4858L54.1926 48.4858L36.24 17.2501L17.8548 48.4858ZM27.4836 45.579C25.7371 45.579 25.2837 43.6668 26.1234 42.6741L34.4257 26.7594C35.084 25.4975 36.914 25.4975 37.5723 26.7594L46.0642 43.0373C46.6697 44.1979 45.8149 45.579 44.4909 45.579L27.4836 45.579ZM30.4064 42.0909L41.5916 42.0909L35.999 31.3705L30.4064 42.0909Z" fill="#EDF5FF"></path><defs><linearGradient id="linear_fill_1_1188_1" x1="36" y1="72" x2="36" y2="0" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#00C6FF" stop-opacity="0.5"/><stop offset="1" stop-color="#00C6FF" stop-opacity="0"/></linearGradient><filter id="filter_1_1188" x="0" y="0" width="72" height="72" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="feFloodId_1_1188"/><feBlend mode="normal" in="SourceGraphic" in2="feFloodId_1_1188" result="shape_1_1188"/><feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha_1_1188"/><feOffset dx="0" dy="0"/><feGaussianBlur stdDeviation="4"/><feComposite in2="hardAlpha_1_1188" operator="arithmetic" k2="-1" k3="1"/><feColorMatrix type="matrix" values="0 0 0 0 0 0 0 0 0 0.4470588235294118 0 0 0 0 1 0 0 0 0.64 0"/><feBlend mode="normal" in2="shape_1_1188" result="innerShadow_0_1_1188"/></filter></defs></svg>
''';

class WarningLightSvgToggleButton extends StatelessWidget {
  const WarningLightSvgToggleButton({
    super.key,
    required this.value,
    required this.onTap,
    this.size = 36,
  });

  final bool value;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: value ? '警示灯开' : '警示灯关',
      child: SizedBox(
        width: size,
        height: size,
        child: Opacity(
          opacity: value ? 1 : 0.72,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SvgPicture.string(
                _warningLightSvg,
                width: size,
                height: size,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
