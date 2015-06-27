function puts(){
  console.log.apply(console, arguments);
}

$(function(){
  puts("ready");
});
