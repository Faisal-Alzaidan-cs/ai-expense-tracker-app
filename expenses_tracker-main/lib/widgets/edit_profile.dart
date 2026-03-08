import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color(0xff41C041),
      ),
      width: double.infinity,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: const Color.fromARGB(255, 8, 117, 8),
            ),
            padding: EdgeInsets.all(12),
            child: Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      "Loading...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      !snapshot.data!.exists) {
                    return Text(
                      "User",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  final username = snapshot.data!.get('username');
                  return Text(
                    username.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              Text(
                "My Account",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Spacer(),
          Icon(
            Icons.edit,
            size: 30,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
