import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _bluetoothOnSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="72" height="72" viewBox="0 0 72 72" fill="none"><circle cx="36" cy="36" r="36" fill="#1B2D4D" fill-opacity="0.4"></circle><path fill-rule="evenodd" fill="url(#linear_border_1_1237_0)" d="M36 72C55.8823 72 72 55.8823 72 36C72 16.1177 55.8823 0 36 0C16.1177 0 0 16.1177 0 36C0 55.8823 16.1177 72 36 72ZM36 2C54.7777 2 70 17.2223 70 36C70 54.7777 54.7777 70 36 70C17.2223 70 2 54.7777 2 36C2 17.2223 17.2223 2 36 2Z"></path><path d="M53.2616 13.0983C53.8846 13.3965 53.9999 14.0616 53.9999 14.9561C53.9999 24.3364 53.9999 33.6937 53.9999 43.0741C53.9999 46.5372 51.8082 49.3582 48.509 50.1609C44.5177 51.1242 40.5265 48.5096 39.8113 44.4502C39.0961 40.5283 41.9337 36.7441 45.925 36.2395C47.7707 36.0102 49.4318 36.4459 50.9545 37.478C51.0237 37.5239 51.0699 37.5697 51.1391 37.5927C51.1622 37.5927 51.1852 37.5927 51.2545 37.6156L51.2545 28.0059C51.1391 28.0518 51.0237 28.0747 50.9084 28.1206C44.8176 30.5287 38.75 32.9598 32.6592 35.368C32.3362 35.4826 32.2901 35.6661 32.2901 35.9643C32.2901 41.2393 32.2901 46.4913 32.2901 51.7663C32.2901 55.2753 29.9599 58.1422 26.5223 58.8532C22.6695 59.6559 18.8858 57.0872 18.1244 53.1424C17.3862 49.4041 20.0163 45.5969 23.7999 44.9318C25.7841 44.5878 27.6067 44.9777 29.2678 46.1015C29.3601 46.1473 29.4293 46.1932 29.5908 46.2849C29.5908 46.0556 29.5908 45.8721 29.5908 45.7116C29.5908 38.3036 29.5908 30.8957 29.5908 23.5107C29.5908 22.4098 29.7754 22.1346 30.7905 21.7218C37.9195 18.8779 52.1542 13.213 52.1542 13.213C52.1542 13.213 52.8694 12.8461 53.2616 13.0754L53.2616 13.0983Z" fill="url(#linear_fill_1_1240)"></path><defs><linearGradient id="linear_border_1_1237_0" x1="36" y1="72" x2="36" y2="0" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#7EA2CF" stop-opacity="0.4"/><stop offset="0.2807" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="0.5394" stop-color="#7DA2CE"/><stop offset="0.7815" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="1" stop-color="#7DA2CE" stop-opacity="0.4"/></linearGradient><linearGradient id="linear_fill_1_1240" x1="36" y1="13" x2="36" y2="59" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#EDF5FF"/><stop offset="1" stop-color="#92C3FF"/></linearGradient></defs></svg>
''';

const _bluetoothOffSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="72" height="72" viewBox="0 0 72 72" fill="none"><circle cx="36" cy="36" r="36" fill="#1B2D4D" fill-opacity="0.4"></circle><path fill-rule="evenodd" fill="url(#linear_border_26_122_0)" d="M36 72C55.8823 72 72 55.8823 72 36C72 16.1177 55.8823 0 36 0C16.1177 0 0 16.1177 0 36C0 55.8823 16.1177 72 36 72ZM36 2C54.7777 2 70 17.2223 70 36C70 54.7777 54.7777 70 36 70C17.2223 70 2 54.7777 2 36C2 17.2223 17.2223 2 36 2Z"></path><path fill-rule="evenodd" d="M37.1108 32.3043C40.6041 30.9046 44.0747 29.5049 47.5681 28.1052C47.6822 28.0593 47.7964 28.0363 47.9105 27.9904L47.9105 37.6049C47.9105 37.6049 47.8192 37.6049 47.7964 37.582C47.7279 37.5361 47.6822 37.4902 47.6137 37.4673C46.1068 36.4347 44.4628 35.9987 42.6362 36.2282C42.4079 36.2511 42.1796 36.3429 41.9513 36.3888L50.5819 43.6627C50.5819 43.4562 50.6276 43.2726 50.6276 43.0661L50.6276 14.9341C50.6276 14.0392 50.5135 13.3737 49.897 13.0754C49.486 12.846 48.801 13.2131 48.801 13.2131C48.801 13.2131 34.7134 18.8808 27.6581 21.7261C26.722 22.0933 26.4937 22.3916 26.4708 23.3553L37.1108 32.3273L37.1108 32.3043ZM55.4569 53.5755C55.1176 53.5729 54.7571 53.458 54.4635 53.2083L17.5433 21.8868C16.8811 21.3361 16.8126 20.3494 17.3606 19.7069C17.9086 19.0415 18.8904 18.9726 19.5297 19.5233L56.4499 50.8449C57.112 51.3956 57.1805 52.3823 56.6326 53.0247C56.3382 53.3887 55.9092 53.5722 55.4569 53.5755ZM55.4569 53.5755L55.4453 53.5755L55.4681 53.5755L55.4569 53.5755ZM26.4709 31.7078L26.4709 46.2786C26.3111 46.1868 26.2426 46.1409 26.1513 46.095C24.5073 44.9477 22.7036 44.5576 20.74 44.9248C16.9954 45.5902 14.3925 49.3993 15.1232 53.1395C15.8995 57.0862 19.6212 59.6562 23.4342 58.8531C26.8362 58.1417 29.1423 55.2964 29.1423 51.7627L29.1423 35.9528C29.1423 35.6545 29.2108 35.4709 29.5076 35.3562C29.8045 35.2415 30.1013 35.1267 30.3753 35.012L26.4709 31.7078ZM37.0194 40.6109C36.5399 41.7811 36.3344 43.0891 36.5856 44.4429C37.3162 48.5273 41.2435 51.1432 45.1935 50.1565C45.9469 49.9729 46.6548 49.6517 47.2941 49.2616L37.0194 40.6109Z" fill="#7DA2CE"></path><defs><linearGradient id="linear_border_26_122_0" x1="36" y1="72" x2="36" y2="0" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#7EA2CF" stop-opacity="0.4"/><stop offset="0.2807" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="0.5394" stop-color="#7DA2CE"/><stop offset="0.7815" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="1" stop-color="#7DA2CE" stop-opacity="0.4"/></linearGradient></defs></svg>
''';

class BluetoothSvgToggleButton extends StatelessWidget {
  const BluetoothSvgToggleButton({
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
      label: value ? '开' : '关',
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SvgPicture.string(
              value ? _bluetoothOnSvg : _bluetoothOffSvg,
              width: size,
              height: size,
            ),
          ),
        ),
      ),
    );
  }
}

const _soundOffSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="72" height="72" viewBox="0 0 72 72" fill="none"><circle cx="36" cy="36" r="36" fill="#1B2D4D" fill-opacity="0.4"></circle><path fill-rule="evenodd" fill="url(#linear_border_1_1242_0)" d="M36 72C55.8823 72 72 55.8823 72 36C72 16.1177 55.8823 0 36 0C16.1177 0 0 16.1177 0 36C0 55.8823 16.1177 72 36 72ZM36 2C54.7777 2 70 17.2223 70 36C70 54.7777 54.7777 70 36 70C17.2223 70 2 54.7777 2 36C2 17.2223 17.2223 2 36 2Z"></path><path fill-rule="evenodd" d="M48.2471 41.4432L48.2471 16.9296C48.2471 16.09 47.8156 15.4602 46.9527 15.0404C46.0897 14.8305 45.2268 15.0404 44.5796 15.6701C41.3436 18.8189 38.1316 21.9443 35.1114 25.093C34.6799 25.5128 34.2485 25.5128 33.817 25.5128L28.6395 25.5128L48.2231 41.4432L48.2471 41.4432ZM54.719 53.1281C55.0306 53.3846 55.4141 53.5013 55.7737 53.5013C56.2531 53.5013 56.7085 53.3147 57.0201 52.9415C57.5954 52.2884 57.5235 51.2855 56.8284 50.7257L18.0686 18.8885C17.3974 18.3287 16.3667 18.3987 15.7914 19.0751C15.2161 19.7281 15.288 20.7311 15.9832 21.2908L54.719 53.1281ZM24.5645 30.5505L24.5645 42.0725C24.5645 44.8014 26.2904 46.4807 29.0949 46.4807L33.841 46.4807C34.2724 46.4807 34.3204 46.5274 34.7039 46.9006L44.1721 56.1135L44.6036 56.5334C45.898 57.373 47.6238 56.9532 48.0553 55.4838L48.0553 49.8394L24.5645 30.5505Z" fill="#7DA2CE"></path><defs><linearGradient id="linear_border_1_1242_0" x1="36" y1="72" x2="36" y2="0" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#7EA2CF" stop-opacity="0.4"/><stop offset="0.2807" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="0.5394" stop-color="#7DA2CE"/><stop offset="0.7815" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="1" stop-color="#7DA2CE" stop-opacity="0.4"/></linearGradient></defs></svg>
''';

const _soundOnSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="72" height="72" viewBox="0 0 72 72" fill="none"><circle cx="36" cy="36" r="36" fill="#1B2D4D" fill-opacity="0.4"></circle><path fill-rule="evenodd" fill="url(#linear_border_2_247_0)" d="M36 72C55.8823 72 72 55.8823 72 36C72 16.1177 55.8823 0 36 0C16.1177 0 0 16.1177 0 36C0 55.8823 16.1177 72 36 72ZM36 2C54.7777 2 70 17.2223 70 36C70 54.7777 54.7777 70 36 70C17.2223 70 2 54.7777 2 36C2 17.2223 17.2223 2 36 2Z"></path><path fill-rule="evenodd" d="M15 42.0758L15 29.9067C15 27.2723 16.7699 25.5006 19.4298 25.5006L24.0997 25.5006C24.473 25.5006 24.7297 25.4007 25.0097 25.1209C28.1129 21.9971 31.2428 18.8732 34.3693 15.7493C35.0226 15.0966 35.7893 14.8168 36.6992 15.1199C37.5159 15.3763 38.0525 16.1057 38.0992 16.9682L38.0992 54.5246C38.0992 54.851 38.0992 55.1507 38.0292 55.4538C37.6325 56.8992 35.9093 57.4853 34.7193 56.5528C34.556 56.4129 34.3893 56.2431 34.2493 56.1032C31.1694 53.026 28.0862 49.9487 25.0296 46.8715C24.7497 46.5917 24.4763 46.5018 24.0797 46.5018L19.4598 46.5018C16.7766 46.5018 15 44.7334 15 42.0758ZM49.6188 45.8124C49.1232 46.4829 48.5722 47.1264 47.9688 47.7407C47.3501 48.3741 47.1295 49.1337 47.2989 49.8188C47.3854 50.2014 47.5908 50.5555 47.9189 50.8579C48.8055 51.6972 50.0688 51.6339 50.9787 50.6781C54.9453 46.5984 56.9285 41.6993 56.9985 36.0112L56.9985 36.0312C57.0146 34.7146 56.8989 33.4238 56.6585 32.1447C56.5559 31.5814 56.4291 31.0244 56.2786 30.4662C55.2986 26.8993 53.502 23.7955 50.8887 21.1845C50.1888 20.4851 49.1855 20.3485 48.3688 20.8148C47.7053 21.1832 47.2689 21.858 47.2689 22.5732C47.2689 22.7707 47.2926 22.9641 47.3589 23.1627C47.5222 23.6289 47.8489 24.0785 48.1988 24.4515C51.4619 28.0176 52.9952 32.1113 52.7687 36.7305C52.7351 37.3883 52.6732 38.0599 52.5687 38.7387C52.344 40.2032 51.9299 41.5773 51.3487 42.8651C50.8795 43.9008 50.3013 44.8832 49.6188 45.8124ZM44.309 37.1602C44.0572 38.8311 43.2893 40.4515 41.9991 41.816C41.5436 42.307 41.3191 42.8855 41.3191 43.4445C41.3191 43.9901 41.5253 44.5231 41.9691 44.9432C42.8557 45.7824 44.1423 45.7058 45.029 44.7733C47.3855 42.3255 48.5288 39.4182 48.5988 36.5507L48.5988 36.4508C48.5988 32.6975 47.2722 29.487 45.009 27.1791C44.0757 26.2466 42.7924 26.2 41.9291 27.0392C41.5037 27.4641 41.2991 27.9843 41.2991 28.5179C41.2991 29.0822 41.5268 29.6604 41.9991 30.1564C43.8934 32.1458 44.6597 34.7057 44.309 37.1602Z" fill="url(#linear_fill_2_250)"></path><defs><linearGradient id="linear_border_2_247_0" x1="36" y1="72" x2="36" y2="0" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#7EA2CF" stop-opacity="0.4"/><stop offset="0.2807" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="0.5394" stop-color="#7DA2CE"/><stop offset="0.7815" stop-color="#7DA2CE" stop-opacity="0.64"/><stop offset="1" stop-color="#7DA2CE" stop-opacity="0.4"/></linearGradient><linearGradient id="linear_fill_2_250" x1="36" y1="15" x2="36" y2="57" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#EDF5FF"/><stop offset="1" stop-color="#92C3FF"/></linearGradient></defs></svg>
''';

class SoundSvgToggleButton extends StatelessWidget {
  const SoundSvgToggleButton({
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
      label: value ? '声音开' : '声音关',
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SvgPicture.string(
              value ? _soundOnSvg : _soundOffSvg,
              width: size,
              height: size,
            ),
          ),
        ),
      ),
    );
  }
}
