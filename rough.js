// // db.students.insert(
// //     {
// //         name: "Sumit",
// //         age: 25,
// //         country: "Nepal",
// //         course:"MBA"
// //     }
// // )


// db.students.insertMany(
//     [
//         {
//             name: "jenny",
//             age: 23,
//             country: "England",
//             course:"BIBM"

//         },
//         {
//             name: "mayank",
//             age: 23,
//             course:"BIBM"

//         },
//         {
//             name: "jeevan",
//             age: 23,
//             country: "England",
//             course:"BIBM",
//             hobby : "cricket"

//         }
//     ]
// )

// db.students.insert(
//     {
//         name: "Dinesh",
//         age: 15,
//         country: "India",
//         course: "C++",
//         date: new Date()

//     }
// )

// db.students.insert(
//     {
//         name: "Rahul",
//         age: 25,
//         country: "Nepal",
//         course: "C",
//         date: new Date(),
//         sr: Math.random()
//     }
// )


// // show all the data
// db.students.find()
// db.students.find().pretty;

// //Search 
// db.students.find(
//     {
//         course:"BIBM"
//     }
// )


// db.students.find(
//     {
//         course:"BIBM"
//     }
// ).pretty();


// db.students.find(
//     {
//         course:"MBA",
//         age: 25
//     }
// ).pretty();


// db.students.find().pretty().limit(2);

// db.students.find().pretty().count();

// db.students.find().sort({name:-1}).pretty();

// db.students.find(25).count({age:-1}).pretty();




// //Update

// db.students.updateOne(
//     {
//         name:"jhon",
//     },
//     {
//         $set:{
//             age:30
//         }
//     },
//     {upsert:true}
// )