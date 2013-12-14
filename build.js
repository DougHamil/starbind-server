require('coffee-script');
var build = require('./build/build');

build(function(error) {
	if(error)
		console.log("Build failed: "+error);
	else
		console.log("Build completed successfully");
});


