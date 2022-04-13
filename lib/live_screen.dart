import 'dart:developer';
import 'dart:math' as math; // import this

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:zebolive/core/constant/app_animations.dart';
import 'package:zebolive/core/enum/user_enum.dart';
import 'package:zebolive/core/utils/global.dart';
import 'package:zebolive/core/utils/size_config.dart';
import 'package:zebolive/ui/screen/live/controller/live_streaming_contoller.dart';
import 'package:zebolive/ui/shared/liveScreenFooter/controller/pk_live_controller.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/constant/app_images.dart';
import '../../../../core/model/live/live_detail_model.dart';
import '../../../../core/model/live/live_list_model.dart';
import '../../../shared/audio_video_control.dart';
import '../../../shared/cached_network_image_view.dart';
import '../../../shared/keyboard_visible.dart';
import '../../../shared/liveScreenFooter/controller/gift/gift_file_controller.dart';
import '../../../shared/liveScreenHeader/widgets/bottom_profile_screen.dart';
import '../../../shared/liveScreenFooter/widgets/fab_menu_button.dart';
import '../../../shared/liveScreenHeader/live_screen_header_controller.dart';
import '../../../shared/live_comment_box.dart';
import '../../../shared/liveScreenFooter/live_screen_footer.dart';
import '../../../shared/liveScreenHeader/live_screen_header.dart';
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
  String? id;
  @override
  void deactivate() {
    super.deactivate();
    // Wakelock.disable();
  }

  @override
  void initState() {
    super.initState();
    fetchLinkData();
    WidgetsBinding.instance!.addObserver(this);
    // Wakelock.enable();
    if (widget.liveListDetails == null) {
      liveStreamingController.startLive();
      log("live Screenlkjhygf");
      print(
          'liveId-------------liveId-------${liveStreamingController.liveModel.liveId}');
    } else {
      liveStreamingController.joinLive(liveId: widget.liveListDetails!.liveId);
      print("live Screen Id==${widget.liveListDetails!.liveId}");
    }
    if (id == null) {
      liveStreamingController.startLive();
      log("live Screenlkjhygf");
      print('liveId----deeplink---------liveId-------$id');
    } else {
      liveStreamingController.joinLive(liveId: int.parse(id!));
      print("live Screen Id==$id");
    }
  }

  void fetchLinkData() async {
    // FirebaseDynamicLinks.getInitialLInk does a call to firebase to get us the real link because we have shortened it.
    var link = await FirebaseDynamicLinks.instance.getInitialLink();

    // This link may exist if the app was opened fresh so we'll want to handle it the same way onLink will.
    handleLinkData(link!);
    // This will handle incoming links if the application is already opened
    FirebaseDynamicLinks.instance.onLink;
  }

  void handleLinkData(PendingDynamicLinkData data) {
    final Uri? uri = data.link;
    if (uri != null) {
      final queryParams = uri.queryParameters;
      if (queryParams.length > 0) {
        id = queryParams['liveid'];
        // verify the username is parsed correctly
        print("My join id: $id");
      }
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LiveScreenHeader(),
                    // if (liveStreamingController.myTrack != null ||
                    //     liveStreamingController.pkTrack != null)
                    const AudioVideoControl(),
                    const Spacer(),
                    const LiveCommentBox(),
                    LiveScreenFooter(),
                  ],
                ),
                FabButton(
                    liveId: "${liveStreamingController.liveModel.liveId}"),
                GetBuilder(
                  builder: (GiftFileController giftFileController) {
                    print('LIVEID:-${widget.liveListDetails?.liveId}');

                    return giftFileController.giftLottieFileQueue.isNotEmpty &&
                            !giftFileController.isGiftLottieShowing
                        ? showGiftAnimation(giftFileController)
                        : Container();
                  },
                ),
                // chatWidget(),
                KeyboardVisibilityBuilder(
                    builder: (context, child, isKeyboardVisible) {
                  liveStreamingController.isHMSMessageTap = isKeyboardVisible;
                  return GetBuilder(builder:
                      (LiveStreamingController liveStreamingController) {
                    return liveStreamingController.isHMSMessageTap
                        ? Container(
                            height: getHeight(400),
                            color: Colors.teal,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: getHeight(50)),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: getHeight(12),
                                          horizontal: getWidth(15)),
                                      height: getHeight(300),
                                      width: double.infinity,
                                      color: AppColors.kScaffoldColor,
                                      child: SingleChildScrollView(
                                        reverse: true,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              height: getHeight(250),
                                              child: ListView.separated(
                                                  itemBuilder: (_, int) {
                                                    return Container(
                                                      height: getHeight(35),
                                                      decoration: BoxDecoration(
                                                          color: AppColors
                                                              .kLoginTextColors,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      getHeight(
                                                                          10))),
                                                      child: Row(children: [
                                                        Container(
                                                          margin:
                                                              EdgeInsets.only(
                                                                  left:
                                                                      getHeight(
                                                                          5)),
                                                          height: getHeight(30),
                                                          width: getHeight(30),
                                                          decoration: const BoxDecoration(
                                                              image: DecorationImage(
                                                                  image: AssetImage(
                                                                      AppImages
                                                                          .pandaIcon))),
                                                        ),
                                                        RichText(
                                                          text: TextSpan(
                                                              text:
                                                                  "User name\t" +
                                                                      ":\t",
                                                              style: TextStyle(
                                                                  color: AppColors
                                                                      .kLoginPageWhiteColor,
                                                                  fontSize:
                                                                      getHeight(
                                                                          14),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700),
                                                              children: [
                                                                TextSpan(
                                                                  text:
                                                                      "Message",
                                                                  style: TextStyle(
                                                                      color: AppColors
                                                                          .userProfileBgColor,
                                                                      fontSize:
                                                                          getHeight(
                                                                              14),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w400),
                                                                )
                                                              ]),
                                                        )
                                                      ]),
                                                    );
                                                  },
                                                  separatorBuilder: (_, int) {
                                                    return Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical:
                                                                  getHeight(6)),
                                                    );
                                                  },
                                                  itemCount: 10),
                                            ),
                                            Container(
                                              margin: EdgeInsets.symmetric(
                                                  horizontal: getHeight(20)),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.white),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child: TextField(
                                                // onChanged: (value) {
                                                //   // value = controller.mobileNumberController.text;
                                                // },
                                                // controller: controller.mobileNumberController,
                                                style: TextStyle(
                                                    color: AppColors
                                                        .userProfileBgColor),
                                                keyboardType:
                                                    TextInputType.text,
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  prefix: SizedBox(
                                                      width: getWidth(20)),
                                                  border: InputBorder.none,
                                                  hintText: "Comments",
                                                  hintStyle: TextStyle(
                                                      color: AppColors
                                                          .kLoginPageWhiteColor),
                                                  suffix: GestureDetector(
                                                    child: Container(
                                                        margin: EdgeInsets.only(
                                                            right:
                                                                getWidth(10)),
                                                        child: Text("send".tr)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Container(
                                    //   margin: EdgeInsets.symmetric(
                                    //       horizontal: getHeight(20)),
                                    //   decoration: BoxDecoration(
                                    //     border: Border.all(color: Colors.white),
                                    //     borderRadius: BorderRadius.circular(5),
                                    //   ),
                                    //   child: TextField(
                                    //     // onChanged: (value) {
                                    //     //   // value = controller.mobileNumberController.text;
                                    //     // },
                                    //     // controller: controller.mobileNumberController,
                                    //     style: TextStyle(
                                    //         color: AppColors.userProfileBgColor),
                                    //     keyboardType: TextInputType.text,
                                    //     decoration: InputDecoration(
                                    //       isDense: true,
                                    //       prefix: SizedBox(width: getWidth(20)),
                                    //       border: InputBorder.none,
                                    //       hintText: "Comments",
                                    //       hintStyle: TextStyle(
                                    //           color:
                                    //               AppColors.kLoginPageWhiteColor),
                                    //       suffix: GestureDetector(
                                    //         child: Container(
                                    //             margin: EdgeInsets.only(
                                    //                 right: getWidth(10)),
                                    //             child: Text("send".tr)),
                                    //       ),
                                    //     ),
                                    //   ),
                                    // ),
                                  ]),
                            ),
                          )
                        : Container();
                  });
                })
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
                  // if(pkLiveController.opponent!.isFollowing == 0)
                  //   GestureDetector(
                  //     onTap: () {
                  //       pkLiveController.followLiveUser(pkLiveController.opponent!.id);
                  //     },
                  //     child: Image(
                  //         height: getHeight(25),
                  //         image: const AssetImage(AppImages.plusLiveImage)),
                  //   )
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
      // List<HMSPeer>? peersList = await _meetingStore.getPeers();
      //
      // peersList?.forEach((element) {
      //   if (!element.isLocal) {
      //     (element.audioTrack as HMSRemoteAudioTrack?)?.setVolume(10.0);
      //     element.auxiliaryTracks?.forEach((element) {
      //       if (element.kind == HMSTrackKind.kHMSTrackKindAudio) {
      //         (element as HMSRemoteAudioTrack?)?.setVolume(10.0);
      //       }
      //     });
      //   }
      // });

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
}

chatWidget() {
  return showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: Get.context as BuildContext,
      builder: (context) {
        return const ChatWidget();
      });
}

class ChatWidget extends StatefulWidget {
  const ChatWidget({Key? key}) : super(key: key);

  @override
  _ChatWidgetState createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  LiveStreamingController liveStreamingController =
      Get.find<LiveStreamingController>();

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(
        builder: (context, child, isKeyboardVisible) {
      liveStreamingController.isHMSMessageTap = isKeyboardVisible;
      return GetBuilder(
          builder: (LiveStreamingController liveStreamingController) {
        return liveStreamingController.isHMSMessageTap
            ? Container(
                height: getHeight(400),
                color: Colors.teal,
                child: Padding(
                  padding: EdgeInsets.only(bottom: getHeight(50)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              vertical: getHeight(12),
                              horizontal: getWidth(15)),
                          height: getHeight(300),
                          width: double.infinity,
                          color: AppColors.kScaffoldColor,
                          child: SingleChildScrollView(
                            reverse: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  height: getHeight(250),
                                  child: ListView.separated(
                                      itemBuilder: (_, int) {
                                        return Container(
                                          height: getHeight(35),
                                          decoration: BoxDecoration(
                                              color: AppColors.kLoginTextColors,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      getHeight(10))),
                                          child: Row(children: [
                                            Container(
                                              margin: EdgeInsets.only(
                                                  left: getHeight(5)),
                                              height: getHeight(30),
                                              width: getHeight(30),
                                              decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                      image: AssetImage(
                                                          AppImages
                                                              .pandaIcon))),
                                            ),
                                            RichText(
                                              text: TextSpan(
                                                  text: "User name\t" + ":\t",
                                                  style: TextStyle(
                                                      color: AppColors
                                                          .kLoginPageWhiteColor,
                                                      fontSize: getHeight(14),
                                                      fontWeight:
                                                          FontWeight.w700),
                                                  children: [
                                                    TextSpan(
                                                      text: "Message",
                                                      style: TextStyle(
                                                          color: AppColors
                                                              .userProfileBgColor,
                                                          fontSize:
                                                              getHeight(14),
                                                          fontWeight:
                                                              FontWeight.w400),
                                                    )
                                                  ]),
                                            )
                                          ]),
                                        );
                                      },
                                      separatorBuilder: (_, int) {
                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: getHeight(6)),
                                        );
                                      },
                                      itemCount: 10),
                                ),
                                Container(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: getHeight(20)),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: TextField(
                                    // onChanged: (value) {
                                    //   // value = controller.mobileNumberController.text;
                                    // },
                                    // controller: controller.mobileNumberController,
                                    style: TextStyle(
                                        color: AppColors.userProfileBgColor),
                                    keyboardType: TextInputType.text,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      prefix: SizedBox(width: getWidth(20)),
                                      border: InputBorder.none,
                                      hintText: "Comments",
                                      hintStyle: TextStyle(
                                          color:
                                              AppColors.kLoginPageWhiteColor),
                                      suffix: GestureDetector(
                                        child: Container(
                                            margin: EdgeInsets.only(
                                                right: getWidth(10)),
                                            child: Text("send".tr)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Container(
                        //   margin: EdgeInsets.symmetric(
                        //       horizontal: getHeight(20)),
                        //   decoration: BoxDecoration(
                        //     border: Border.all(color: Colors.white),
                        //     borderRadius: BorderRadius.circular(5),
                        //   ),
                        //   child: TextField(
                        //     // onChanged: (value) {
                        //     //   // value = controller.mobileNumberController.text;
                        //     // },
                        //     // controller: controller.mobileNumberController,
                        //     style: TextStyle(
                        //         color: AppColors.userProfileBgColor),
                        //     keyboardType: TextInputType.text,
                        //     decoration: InputDecoration(
                        //       isDense: true,
                        //       prefix: SizedBox(width: getWidth(20)),
                        //       border: InputBorder.none,
                        //       hintText: "Comments",
                        //       hintStyle: TextStyle(
                        //           color:
                        //               AppColors.kLoginPageWhiteColor),
                        //       suffix: GestureDetector(
                        //         child: Container(
                        //             margin: EdgeInsets.only(
                        //                 right: getWidth(10)),
                        //             child: Text("send".tr)),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ]),
                ),
              )
            : Container();
      });
    });
  }
}
