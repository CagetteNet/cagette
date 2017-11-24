package utils;

import haxe.Json;
import js.Promise;
import js.html.XMLHttpRequest;

@:enum abstract HttpMethod(String) to String {
  var POST = 'POST';
  var GET = 'GET';
  var HEAD = 'HEAD';
  var PUT = 'PUT';
  var DELETE = 'DELETE';
  var TRACE = 'TRACE';
  var OPTIONS = 'OPTIONS';
  var CONNECT = 'CONNECT';
  var PATCH = 'GET';
}

@:enum abstract FetchFormat(String) from String to String {
  var PLAIN_TEXT = "text/plain";
  var JSON = "application/json";
}

class HttpUtil
{
  static public function fetch(
    url: String,
    ?method: HttpMethod = GET,
    ?params: Dynamic = null,
    ?accept: FetchFormat = PLAIN_TEXT,
    ?contentType: String = "application/json"
  ): Promise<Dynamic> {
    return new Promise(function(resolve: Dynamic->Void, reject) {
      var data: String = null;
      if (params != null)
      {
        if (params.body != null)
          data = Json.stringify(params.body);
        else
        {
          url += (url.indexOf('?') > -1) ? '&' : '?';
          url += objToString(params);
        }
      }

      var http = new XMLHttpRequest();
      http.open(method, url, true);

      if (contentType != null && contentType.length > 0)
        http.setRequestHeader("Content-type", contentType);

      if (accept != null)
        http.setRequestHeader("Accept", accept);

      http.onreadystatechange = function() {
        if (http.readyState == 4)
        {
          switch (http.status)
          {
            case 200:
              switch (accept)
              {
                case JSON:
                  try {
                    var json = Json.parse(http.responseText);
                    resolve(json);
                  }
                  catch (err: Dynamic)
                    reject(err);

                default:
                  resolve(http.responseText);
              }

            case 204:
              resolve(true);

            default:
              reject(http.responseText);
          }
        }
      };

      http.send(data);
    });
  }

  static public function objToString(obj: Dynamic): String
  {
    var str = "";
    var cpt = 0;
    for (key in Reflect.fields(obj))
    {
      var value: Dynamic = Reflect.field(obj, key);
      if (value == null) continue;

      if (cpt++ > 0)
        str += "&";

      if (Std.is(value, Array) && value.length > 0)
        str += '$key=${value.join(";")}';
      else if (Std.string(value) != "") // String / Int / Float
        str += '$key=${StringTools.trim(Std.string(value))}';
    }
    return str;
  }

}
