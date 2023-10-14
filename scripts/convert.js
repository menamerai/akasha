const bigInt = require('big-integer');

const hexString = "ae56b2c01e4cbdfb645c3edaa23ea63ff93425c56e41320461f2623d46ff4ecb";
const integer = bigInt(hexString, 16);

console.log(integer.toString());
