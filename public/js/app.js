function puts(){
  console.log.apply(console, arguments);
}

function _api(method, url, params, fnOk, fnNg){
  $.post(url, {
    _method: method,
    apiParams: JSON.stringify(params)
  }, function(data){
    if(data.status !== "OK"){
      fnNg(data.data);
      return;
    }
    fnOk(data.data);
  });
}

$(function(){
  _api("get", "/api/graph", {
    dir: "TODO"
  }, function(data){
    puts("OK", data);
  }, function(data){
    puts("NG", data);
  });
});
