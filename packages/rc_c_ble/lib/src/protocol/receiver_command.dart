enum ReceiverCommand {
  receiverInfo(0x01),
  controlHeartbeat(0x02),
  readFailsafe(0x07),
  writeFailsafe(0x08),
  firmwareInfo(0x11),
  startUpgradeBoot(0x12),
  setUpgradeLength(0x13),
  sendUpgradeChunk(0x14);

  const ReceiverCommand(this.id);

  final int id;

  static ReceiverCommand? fromId(int id) {
    for (final command in values) {
      if (command.id == id) {
        return command;
      }
    }
    return null;
  }
}
