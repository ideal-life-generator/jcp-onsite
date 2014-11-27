var child_process = require("child_process");

child_process.exec("coffee -cw .", function(a, b, c) {
	console.log(a, b, c);
});

child_process.exec("sass --watch .", function(a, b, c) {
	console.log(a, b, c);
});