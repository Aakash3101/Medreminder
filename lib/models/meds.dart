import 'package:firebase_database/firebase_database.dart';

class Meds {
	
	String key;
	String userId;
	String medName;
	String medType;
	int qty;
	String time;
	String day;
  bool completed;

	Meds(
		this.userId,
		this.medName,
		this.medType,
		this.qty,
		this.time,
		this.day,
    this.completed
	);

	Meds.fromSnapshot(DataSnapshot snapshot) :
		key = snapshot.key,
		userId = snapshot.value["userId"],
		medName = snapshot.value["medName"],
		medType = snapshot.value["medType"],
		qty = snapshot.value["qty"],
		time = snapshot.value["time"],
		day = snapshot.value["day"],
		completed = snapshot.value["completed"];

	toJson() {
	  return {
	  	"userId": userId,
	  	"medName": medName,
	  	"medType": medType,
	  	"qty": qty,
	  	"time": time,
	  	"day": day,
	  	"completed": completed
	  };
	}
}