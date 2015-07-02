var Commit;

function puts(){
  console.log.apply(console, arguments);
}


Commit = (function(){
  
  function Commit(){}
  var __ = Commit.prototype;

  Commit.fromObject = function(o){
    var c = new Commit();
    c.author = o.author;
    c.committer = o.committer;
    c.msg = o.msg;
    c.cid = o.cid;
    c.parents = o.parents;
    return c;
  };

  return Commit;
})();


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
