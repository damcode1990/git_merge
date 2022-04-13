import 'dart:developer';
import 'dart:math' as math; // import this

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:wakelock/wakelock.dart';
import 'package:zebolive/core/constant/app_animations.dart';
import 'package:zebolive/core/utils/global.dart';
import 'package:zebolive/core/utils/size_config.dart';
import 'package:zebolive/ui/screen/live/controller/live_streaming_contoller.dart';
import 'package:zebolive/ui/shared/liveScreenFooter/controller/comments/comments_controller.dart';
import 'package:zebolive/ui/shared/liveScreenFooter/controller/pk_live_controller.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_images.dart';
import '../../../../core/model/live/live_detail_model.dart';
import '../../../../core/model/live/live_list_model.dart';
import '../../../../core/model/live/live_message_model.dart';
import '../../../shared/audio_video_control.dart';
import '../../../shared/cached_network_image_view.dart';
import '../../../shared/liveScreenFooter/controller/gift/gift_file_controller.dart';
import '../../../shared/liveScreenFooter/live_screen_footer.dart';
import '../../../shared/liveScreenFooter/widgets/fab_menu_button.dart';
import '../../../shared/liveScreenHeader/live_screen_header.dart';
import '../../../shared/liveScreenHeader/live_screen_header_controller.dart';
import '../../../shared/liveScreenHeader/widgets/bottom_profile_screen.dart';
import '../../../shared/live_comment_box.dart';
import 'gift_animation.dart';

class LiveScreen extends StatefulWidget {
  static const String routeName = "/LiveScreen";
  LiveListDetails? liveListDetails;
  LiveScreen({Key? key, this.liveListDetails}) : super(key: key);
  @override
  _LiveScreenState createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> with WidgetsBindingObserver {
  PageController controller = PageController();
  LiveStreamingController liveStreamingController =
      Get.find<LiveStreamingController>();
  LiveScreenHeaderController liveScreenHeaderController =
      Get.put(LiveScreenHeaderController());
  TextEditingController msg = TextEditingController();

  FocusNode inputNode = FocusNode();
  @override
  void deactivate() {
    super.deactivate();
    Wakelock.disable();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    Wakelock.enable();
    if (widget.liveListDetails == null) {
      liveStreamingController.startLive();
    } else {
      liveStreamingController.joinLive(liveId: widget.liveListDetails!.liveId);
    }
  }

  @override
  Widget build(BuildContext context) {
    log("LiveScreen BUILD");
    return WillPopScope(
      onWillPop: () async {
        Get.find<LiveScreenHeaderController>().quitLive();
        return false;
      },
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(AppImages.LiveBackgroundImage1),
                    fit: BoxFit.fill),
              ),
              child: Stack(children: [
                GetBuilder(
                  builder: (LiveStreamingController liveStreamingController) {
                    log("LIVE SCREEN UPDATE TRACK ${liveStreamingController.myTrack} ${liveStreamingController.pkTrack}");
                    if (liveStreamingController.pkTrack != null &&
                        liveStreamingController.myTrack != null) {
                      return pkLiveView();
                    } else if (liveStreamingController.myTrack != null ||
                        liveStreamingController.pkTrack != null) {
                      return singleLiveView();
                    } else {
                      return noLiveView();
                    }
                  },
                ),
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LiveScreenHeader(),
                      AudioVideoControl(),
                      Spacer(),
                      SingleChildScrollView(child: const LiveCommentBox()),
                      GetBuilder<CommentsController>(
                        builder: (controller) {
                          if (controller.isOpen.value) {
                            intilizeNode();
                          }

                          return controller.isOpen.value
                              ? Container(
                                  height: 280,
                                  color: Colors.white,
                                  child: Column(
                                    children: [
                                      TextField(
                                        // onChanged: (value) {
                                        //   // value = controller.mobileNumberController.text;
                                        // },
                                        // controller: controller.mobileNumberController,
                                        controller: msg,
                                        focusNode: inputNode,
                                        style: const TextStyle(
                                            color: Colors.black),
                                        keyboardType: TextInputType.text,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          prefix: SizedBox(width: getWidth(20)),
                                          border: InputBorder.none,
                                          hintText: "Comments",
                                          hintStyle: const TextStyle(
                                              color: Colors.grey),
                                          suffix: GestureDetector(
                                            onTap: () {
                                              LiveStreamingController liveS =
                                                  Get.put(
                                                      LiveStreamingController());
                                              LiveMessageModel
                                                  liveMessageModel =
                                                  LiveMessageModel();
                                              liveMessageModel.message =
                                                  msg.text;
                                              liveMessageModel.userId = 1234;
                                              liveS.addMessage(
                                                  liveMessageModel:
                                                      liveMessageModel);

                                              print(
                                                  'MessageList ${liveStreamingController.messageList[0].message}');
                                            },
                                            child: Container(
                                                margin: EdgeInsets.only(
                                                    right: getWidth(10)),
                                                child: Text("send".tr)),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              : SizedBox();
                        },
                      ),
                      LiveScreenFooter()
                    ],
                  ),
                ),
                FabButton(),
                GetBuilder(
                  builder: (GiftFileController giftFileController) {
                    return giftFileController.giftLottieFileQueue.isNotEmpty &&
                            !giftFileController.isGiftLottieShowing
                        ? showGiftAnimation(giftFileController)
                        : Container();
                  },
                ),

                // chatWidget(),
                // Spacer(),
                // KeyboardVisibilityBuilder(
                //     builder: (context, child, isKeyboardVisible) {
                //   // liveScreenHeaderController.isOpenKeyboard = isKeyboardVisible;
                //   return GetBuilder(builder:
                //       (LiveScreenHeaderController liveScreenHeaderController) {
                //     return liveScreenHeaderController.isOpenKeyboard == true
                //         ? Container(
                //             margin:
                //                 EdgeInsets.symmetric(horizontal: getHeight(20)),
                //             decoration: BoxDecoration(
                //               border: Border.all(color: Colors.white),
                //               borderRadius: BorderRadius.circular(5),
                //             ),
                //             child: TextField(
                //               // onChanged: (value) {
                //               //   // value = controller.mobileNumberController.text;
                //               // },
                //               // controller: controller.mobileNumberController,
                //               controller: msg,
                //               style: const TextStyle(
                //                   color: AppColors.userProfileBgColor),
                //               keyboardType: TextInputType.text,
                //               decoration: InputDecoration(
                //                 isDense: true,
                //                 prefix: SizedBox(width: getWidth(20)),
                //                 border: InputBorder.none,
                //                 hintText: "Comments",
                //                 hintStyle: const TextStyle(
                //                     color: AppColors.kLoginPageWhiteColor),
                //                 suffix: GestureDetector(
                //                   onTap: () {
                //                     LiveStreamingController liveS =
                //                         Get.put(LiveStreamingController());
                //                     LiveMessageModel liveMessageModel =
                //                         LiveMessageModel();
                //                     liveMessageModel.message = msg.text;
                //                     liveMessageModel.userId = 1234;
                //                     liveS.addMessage(
                //                         liveMessageModel: liveMessageModel);
                //
                //                     print(
                //                         'MessageList ${liveStreamingController.messageList[0].message}');
                //                   },
                //                   child: Container(
                //                       margin:
                //                           EdgeInsets.only(right: getWidth(10)),
                //                       child: Text("send".tr)),
                //                 ),
                //               ),
                //             ),
                //           )
                //         : Container();
                //   });
                // })
              ]),
            ),
          )),
    );
  }

  Widget showGiftAnimation(GiftFileController giftFileController) {
    log("showGiftAnimation ${giftFileController.giftLottieFileQueue[0]}");
    giftFileController.isGiftLottieShowing = true;
    return GiftAnimation(
      giftUrl: giftFileController.giftLottieFileQueue[0],
      onLottieComplete: () {
        giftFileController.isGiftLottieShowing = false;
        giftFileController.giftLottieFileQueue.removeAt(0);
        giftFileController.update();
      },
    );
  }

  Widget pkLiveView() {
    String winnerUserName = "";
    bool isTie = false;
    String resultStr = "Result";
    PKLiveController pkLiveController = Get.find<PKLiveController>();
    showTimerOrResult() {
      return pkLiveController.currPKTime == 0
          ? Container(
              height: getHeight(32),
              width: getWidth(100),
              decoration: const BoxDecoration(
                color: AppColors.userProfileBgColor,
                borderRadius: BorderRadius.all(
                  Radius.circular(25),
                ),
              ),
              child: Center(
                child: Text(
                  resultStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            )
          : Container(
              height: getHeight(32),
              width: getWidth(80),
              decoration: const BoxDecoration(
                color: AppColors.userProfileBgColor,
                borderRadius: BorderRadius.all(
                  Radius.circular(25),
                ),
              ),
              child: Center(
                child: Text(
                  secToMin(pkLiveController.currPKTime),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            );
    }

    Widget showTopUsers(List<TopUserModel>? topUsers) {
      return topUsers == null
          ? Container()
          : Row(
              children: [
                ...topUsers.asMap().entries.map((entry) {
                  return GestureDetector(
                    onTap: () {
                      profileBottomSheet(entry.value.id);
                    },
                    child: CircleAvatar(
                      maxRadius: getHeight(16),
                      backgroundColor: AppColors.userProfileBgColor,
                      child: CachedNetworkImage(
                        imageUrl: entry.value.image,
                        placeholder: (context, url) => Image(
                          height: getHeight(31),
                          image: const AssetImage(AppImages.creatorLogo),
                        ),
                        errorWidget: (context, url, error) => Image(
                          height: getHeight(28),
                          image: const AssetImage(AppImages.creatorLogo),
                        ),
                      ),
                    ),
                  );
                }).toList()
              ],
            );
    }

    Widget opponentUsername() {
      return pkLiveController.opponent == null
          ? Container()
          : Container(
              width: getWidth(100),
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                      onTap: () {
                        profileBottomSheet(pkLiveController.opponent!.id);
                      },
                      child: CachedNetworkImageView(
                        width: 30,
                        imageURL: pkLiveController.opponent!.image,
                        boxShape: BoxShape.circle,
                        placeHolder: ImagePlaceHolder.userDP,
                      )),
                  SizedBox(
                    width: getWidth(3),
                  ),
                  Expanded(
                    child: AutoSizeText(
                      pkLiveController.opponent!.name,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      overflowReplacement: Text(
                        pkLiveController.opponent!.name,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
    }

    return GetBuilder(builder: (PKLiveController pkLiveController) {
      log("showTimerOrResult ${pkLiveController.pkResult}");
      if (pkLiveController.pkResult != null) {
        log("showTimerOrResult1 ${pkLiveController.pkResult!.result.isTie}");
        resultStr =
            winnerUserName = pkLiveController.pkResult!.result.winner.username;
        if (resultStr == "") {
          resultStr =
              pkLiveController.pkResult!.result.isTie ? "It's draw." : "";
          isTie = true;
        }
      }

      return Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: getHeight(250),
              color: Colors.white,
              child: Stack(alignment: Alignment.center, children: [
                Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          HMSVideoView(
                            track: liveStreamingController.myTrack!,
                            setMirror: true,
                          ),
                          const AudioVideoControl(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          HMSVideoView(
                            track: liveStreamingController.pkTrack!,
                            setMirror: true,
                          ),
                          opponentUsername(),
                        ],
                      ),
                    ),
                  ],
                ),
                if (winnerUserName != "")
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 20,
                    child: Row(
                      children: [
                        userController.user.username == winnerUserName
                            ? Expanded(
                                child: SizedBox(
                                    height: getHeight(250),
                                    child: Lottie.asset(AppAnim.pkWonAnim)),
                              )
                            : Expanded(
                                child: SizedBox(
                                    height: getHeight(250),
                                    child: Lottie.asset(AppAnim.pkLoseAnim)),
                              ),
                        userController.user.username == winnerUserName
                            ? Expanded(
                                child: Transform(
                                  transform: Matrix4.rotationY(math.pi),
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                      height: getHeight(250),
                                      child: Lottie.asset(AppAnim.pkLoseAnim)),
                                ),
                              )
                            : Expanded(
                                child: Transform(
                                  transform: Matrix4.rotationY(math.pi),
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                      height: getHeight(250),
                                      child: Lottie.asset(AppAnim.pkWonAnim)),
                                ),
                              ),
                      ],
                    ),
                  ),
                SizedBox(
                    height: getHeight(250),
                    child: Lottie.asset(AppAnim.pkFireAnim)),
                if (isTie)
                  SizedBox(
                      height: getHeight(250),
                      child: Lottie.asset(AppAnim.pkDrawAnim)),
                Positioned(
                  left: getHeight(2),
                  right: getHeight(2),
                  bottom: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      showTopUsers(
                          pkLiveController.giftPKLive?.sender.topUsers),
                      showTimerOrResult(),
                      showTopUsers(
                          pkLiveController.giftPKLive?.receiver.topUsers),
                    ],
                  ),
                ),
              ]),
            ), // Battle Container
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: getHeight(10),
                    color: AppColors.kCreatorButtonColor4,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: getHeight(10),
                    color: AppColors.userProfileBgColor,
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(getHeight(5)),
              child: Row(
                children: [
                  Container(
                      decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.5),
                          shape: BoxShape.circle),
                      child: const Icon(
                        Icons.star,
                        color: Colors.yellowAccent,
                      )),
                  SizedBox(
                    width: getWidth(8),
                  ),
                  GetBuilder(builder: (PKLiveController pkLiveController) {
                    return Text(
                      pkLiveController.pkMyCoin.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    );
                  }),
                  const Spacer(),
                  GetBuilder(builder: (PKLiveController pkLiveController) {
                    return Text(
                      pkLiveController.pkOpponentCoin.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    );
                  }),
                  SizedBox(
                    width: getWidth(8),
                  ),
                  Container(
                      decoration: const BoxDecoration(
                          color: Colors.purpleAccent, shape: BoxShape.circle),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                      )),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget singleLiveView() {
    return SizedBox(
      height: getHeight(640),
      child: HMSVideoView(
        track:
            liveStreamingController.myTrack ?? liveStreamingController.pkTrack!,
        setMirror: true,
      ),
    );
  }

  Widget noLiveView() {
    return Center(
      child: Container(
        height: getHeight(380),
        decoration: const BoxDecoration(
          image: DecorationImage(
            opacity: 0.5,
            image: AssetImage(AppImages.defaultLiveBackgroundImage),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    log("LiveScreen didChangeAppLifecycleState $state");
    if (state == AppLifecycleState.resumed) {
      if (liveStreamingController.isVideoOn) {
        liveStreamingController.startCapturing();
      } else {
        liveStreamingController.stopCapturing();
      }
    } else if (state == AppLifecycleState.paused) {
      if (liveStreamingController.isVideoOn) {
        liveStreamingController.stopCapturing();
      }
    } else if (state == AppLifecycleState.inactive) {
      if (liveStreamingController.isVideoOn) {
        liveStreamingController.stopCapturing();
      }
    }
  }

  void intilizeNode() {
    FocusScope.of(context).requestFocus(inputNode);
  }
}
