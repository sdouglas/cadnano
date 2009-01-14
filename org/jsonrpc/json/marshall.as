// ActionScript file

package org.jsonrpc.json{


    public function marshall(o:Object):*{
        var s:Array=[]

        if(o===null){
            return 'null';
        }else if( o.hasOwnProperty('toJSON')){
            return o.toJSON();
        }else if(o is String){
            return  '"' +o.replace(/\\/g,"\\\\").replace(/\"/g,"\\\"").replace(/\n/g, "\\n").replace(/\r/g,"\\r") + '"';
        }else if(o is Boolean){
            return o==true ? 'true' : 'false'
        }else if(o is Number){
            return "" + o;
        }else if(o is Date){
            return date2JSON(o as Date);
        }else if(o is Array){
            for each(var item:Object in o){
                s.push(marshall(item));
            }
            return '[' +s.join(",") + ']';
        }else{
            for(var name:String  in o){
                s.push(marshall(name) + ':' + marshall(o[name]))
            }
            return '{' + s.join(',') + '}';
        }
    }
}


function date2JSON(date:Date):String{
    var y:Number = date.getUTCFullYear()
    var m:Number = date.getUTCMonth() + 1
    var d:Number = date.getUTCDate()
    var h:Number = date.getUTCHours()
    var min:Number = date.getUTCMinutes()
    var s:Number = date.getUTCSeconds()

    return '{"__jsonclass__":["DateTime", [' + [y, m, d, h, min, s].join(',') + ']]}';
}