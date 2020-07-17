const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();




exports.onCreateActivityFeedItem = functions.firestore
    .document('/feed/{userId}/feedItems/{activityFeedItem}')
    .onCreate(async(snapshot, context) => {
        const userId = context.params.userId;
        const userRef = admin.firestore().doc(`users/${userId}`);
        const doc = await userRef.get();


        const androidNotificationToken = doc.data().androidNotificationToken;
        const createActivityFeedItem = snapshot.data();

        if (androidNotificationToken) {
            sendNotification(androidNotificationToken, createActivityFeedItem);
        } else {
            console.log("No token for user, can not send notification.")
        }

        function sendNotification(androidNotificationToken, activityFeedItem) {
            let body;

            switch (activityFeedItem.type) {
                case "comment":
                    body = `${activityFeedItem.username} commented: ${activityFeedItem.commentData}`;
                    break;

                case "like":
                    body = `${activityFeedItem.username} liked your post`;
                    break;

                case "follow":
                    body = `${activityFeedItem.username} started following you`;
                    break;

                case "friend":
                    body = `${activityFeedItem.username} become your friend`;
                    break;

                default:
                    break;
            }

            const message = {
                notification: { body },
                token: androidNotificationToken,
                data: { recipient: userId },
            };

            admin.messaging().send(message)
                .then(response => {
                    console.log("Successfully sent message", response);
                })
                .catch(error => {
                    console.log("Error sending message", error);
                })

        }
    });



exports.onCreateFollower = functions.firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onCreate(async(snapshot, context) => {

        console.log("Follower Created", snapshot.id);

        const userId = context.params.userId;

        const followerId = context.params.followerId;

        const followedUserPostsRef = admin
            .firestore()
            .collection("posts")
            .doc(userId)
            .collection("usersPosts");

        const followTimelinePostsRef = admin
            .firestore()
            .collection("followTimeline")
            .doc(followerId)
            .collection("followTimelinePosts");

        const querySnapshot = await followedUserPostsRef.get();

        querySnapshot.forEach(doc => {
            if (doc.exists) {
                const postId = doc.id;
                const postData = doc.data();
                followTimelinePostsRef.doc(postId).set(postData);
            }
        });
    });


exports.onCreateFriend = functions.firestore
    .document("/friends/{userId}/userFriends/{friendId}")
    .onCreate(async(snapshot, context) => {

        console.log("Friend Created", snapshot.id);

        const userId = context.params.userId;

        const friendId = context.params.friendId;

        const friendsUserPostsRef = admin
            .firestore()
            .collection("posts")
            .doc(userId)
            .collection("usersPosts");

        const friendTimelinePostsRef = admin
            .firestore()
            .collection("friendTimeline")
            .doc(friendId)
            .collection("friendTimelinePosts");

        const querySnapshot = await friendsUserPostsRef.get();

        querySnapshot.forEach(doc => {
            if (doc.exists) {
                const postId = doc.id;
                const postData = doc.data();
                friendTimelinePostsRef.doc(postId).set(postData);
            }
        });
    });



exports.onDeleteFollower = functions.firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onDelete(async(snapshot, context) => {

        console.log("Follower Deleted", snapshot.id);

        const userId = context.params.userId;

        const followerId = context.params.followerId;

        const followTimelinePostsRef = admin
            .firestore()
            .collection("followTimeline")
            .doc(followerId)
            .collection("followTimelinePosts")
            .where("ownerId", "==", userId);

        const querySnapshot = await followTimelinePostsRef.get();
        querySnapshot.forEach(doc => {
            if (doc.exists) {
                doc.ref.delete();
            }
        });
    });

exports.onDeleteFriend = functions.firestore
    .document("/friends/{userId}/userFriends/{friendId}")
    .onDelete(async(snapshot, context) => {

        console.log("Friend Deleted", snapshot.id);

        const userId = context.params.userId;

        const friendId = context.params.friendId;

        const friendTimelinePostsRef = admin
            .firestore()
            .collection("friendTimeline")
            .doc(friendId)
            .collection("friendTimelinePosts")
            .where("ownerId", "==", userId);

        const querySnapshot = await friendTimelinePostsRef.get();
        querySnapshot.forEach(doc => {
            if (doc.exists) {
                doc.ref.delete();
            }
        });
    });



exports.onCreateFollowPost = functions.firestore
    .document("/posts/{userId}/usersPosts/{postId}")
    .onCreate(async(snapshot, context) => {

        const postCreated = snapshot.data();

        const userId = context.params.userId;

        const postId = context.params.postId;

        const userFollowersRef = admin
            .firestore()
            .collection("followers")
            .doc(userId)
            .collection("userFollowers");

        const querySnapshot = await userFollowersRef.get();

        querySnapshot.forEach(doc => {
            const followerId = doc.id;

            admin
                .firestore()
                .collection("followTimeline")
                .doc(followerId)
                .collection("followTimelinePosts")
                .doc(postId)
                .set(postCreated);
        });
    });


exports.onCreateFriendPost = functions.firestore
    .document("/posts/{userId}/usersPosts/{postId}")
    .onCreate(async(snapshot, context) => {

        const postCreated = snapshot.data();

        const userId = context.params.userId;

        const postId = context.params.postId;

        const userFriendsRef = admin
            .firestore()
            .collection("friends")
            .doc(userId)
            .collection("userFriends");

        const querySnapshot = await userFriendsRef.get();

        querySnapshot.forEach(doc => {
            const friendId = doc.id;

            admin
                .firestore()
                .collection("friendTimeline")
                .doc(friendId)
                .collection("friendTimelinePosts")
                .doc(postId)
                .set(postCreated);
        });
    });




exports.onUpdateFollowPost = functions.firestore
    .document("/posts/{userId}/usersPosts/{postId}")
    .onUpdate(async(change, context) => {
        const postUpdated = change.after.data();
        const userId = context.params.userId;
        const postId = context.params.postId;

        const userFollowersRef = admin
            .firestore()
            .collection("followers")
            .doc(userId)
            .collection("userFollowers");

        const querySnapshot = await userFollowersRef.get();

        querySnapshot.forEach(doc => {
            const followerId = doc.id;

            admin
                .firestore()
                .collection("followTimeline")
                .doc(followerId)
                .collection("followTimelinePosts")
                .doc(postId)
                .get()
                .then(doc => {
                    if (doc.exists) {
                        doc.ref.update(postUpdated);
                    }
                });
        });
    });


exports.onUpdateFriendPost = functions.firestore
    .document("/posts/{userId}/usersPosts/{postId}")
    .onUpdate(async(change, context) => {
        const postUpdated = change.after.data();
        const userId = context.params.userId;
        const postId = context.params.postId;

        const userFriendsRef = admin
            .firestore()
            .collection("friends")
            .doc(userId)
            .collection("userFriends");

        const querySnapshot = await userFriendsRef.get();

        querySnapshot.forEach(doc => {
            const friendId = doc.id;

            admin
                .firestore()
                .collection("friendTimeline")
                .doc(friendId)
                .collection("friendTimelinePosts")
                .doc(postId)
                .get()
                .then(doc => {
                    if (doc.exists) {
                        doc.ref.update(postUpdated);
                    }
                });
        });
    });




exports.onDeleteFollowPost = functions.firestore
    .document("/posts/{userId}/usersPosts/{postId}")
    .onDelete(async(snapshot, context) => {
        const userId = context.params.userId;
        const postId = context.params.postId;

        const userFollowersRef = admin
            .firestore()
            .collection("followers")
            .doc(userId)
            .collection("userFollowers");

        const querySnapshot = await userFollowersRef.get();

        querySnapshot.forEach(doc => {
            const followerId = doc.id;

            admin
                .firestore()
                .collection("followTimeline")
                .doc(followerId)
                .collection("followTimelinePosts")
                .doc(postId)
                .get()
                .then(doc => {
                    if (doc.exists) {
                        doc.ref.delete();
                    }
                });
        });
    });

exports.onDeleteFriendPost = functions.firestore
    .document("/posts/{userId}/usersPosts/{postId}")
    .onDelete(async(snapshot, context) => {
        const userId = context.params.userId;
        const postId = context.params.postId;

        const userFriendsRef = admin
            .firestore()
            .collection("friends")
            .doc(userId)
            .collection("userFriends");

        const querySnapshot = await userFriendsRef.get();

        querySnapshot.forEach(doc => {
            const friendId = doc.id;

            admin
                .firestore()
                .collection("friendTimeline")
                .doc(friendId)
                .collection("friendTimelinePosts")
                .doc(postId)
                .get()
                .then(doc => {
                    if (doc.exists) {
                        doc.ref.delete();
                    }
                });
        });
    });