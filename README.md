# rtmbuild2

## rtmbuildとの差異

https://github.com/start-jsk/rtmros_common/tree/master/rtmbuild

* パッケージをまたいだidlのincludeの対応
* 関数に関係するstructだけではなく、全てのstructを変換する
* 別のパッケージで変換したstructは、再度変換するのではなく再利用する
* https://github.com/start-jsk/rtmros_common/issues/1062#issuecomment-1179733095 の実装
* non exist dependencyを無くしたことで`cmake_policy(SET CMP0046 OLD)`なしでもビルド可能
* openhrp3への依存なし

## future work

* ServiceBridgeはあるが、TopicBridgeが欲しい
  * 今はTopicBridgeを手動生成している https://github.com/Naoki-Hiraoka/rtmros_msg_bridge
  * https://github.com/start-jsk/rtmros_common/blob/master/rosnode_rtc/scripts/rtmros-data-bridge.py は型を動的に定義しているので、c++で使えない
* idl側とmsg側で両方とも既存の型を使いたい。また、データ変換規則を追加できるようにしたい.
  * 例えば、RTC::TimeをROSのtimeに変換する. Bridgeでusecとnsecを変換する.
  * 例えば、RTC::TimedPose3Dをgeometry_msgs::PoseStampedに変換する. Bridgeでrpyとquaternionを変換する.
* idl->msg/srvはあるが、msg/srv->idlが欲しい