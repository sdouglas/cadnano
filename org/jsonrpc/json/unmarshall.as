package org.jsonrpc.json{

public function unmarshall(s:String):*{
    var stack:Array=[[]]
        var idx:int=0
    
        var skip:Boolean=true;
        var c:String;
        var value:*;
        var top:*;
        var strArray:Array;
        var numStart:int;
        
        while(true) {
            skip=true;
            c=s.charAt(idx)

            //skip white space
            while(c===' ' || c === '\n' || c === '\r'  || c === '\t') {
                c=s.charAt(++idx);
            }

            if (idx>=s.length) {
                idx=-1;
                break;
            }

            idx+=1
            switch(c) {
                case '{':
                    stack.push({})
                    break;
                case '[':
                    stack.push([])
                    break;
                case ':': case ',':
                    break;
                case '}': case ']':
                    value=stack.pop()
                    skip = false;
                    break;
                case '"': case "'":
                    skip = false;
                    strArray=[];
                    var endDelimiter:String=c;
                    c=s.charAt(idx);
                    while(c != endDelimiter) {
                        if (c==='\\') {
                            c=s.charAt(++idx)
                            switch(c) {
                                case '"': case "'":
                                    strArray.push(c);
                                    break;
                                case 'r':
                                    strArray.push('\r');
                                    break;
                                case 'n':
                                    strArray.push('\n');
                                    break;
                                case 't':
                                    strArray.push('\t');
                                    break;
                            }
                        } else {
                            strArray.push(c);
                        }
                        c=s.charAt(++idx);
                    }
                    idx+=1;
                    value=strArray.join('');
                    break;
                default: //number or null, true, false
                    skip = false
                    if (c==='-' || (c>='0' && c<='9')) {
                        numStart=idx-1;
                        c=s.charAt(idx);
                        while(c>='0' && c<='9') {
                            c=s.charAt(++idx);
                        }
                        if (c==='.') {
                            c=s.charAt(++idx);
                            while(c>='0' && c<='9') {
                                c=s.charAt(++idx);
                            }
                        }
                        if (c==='e' || c ==='E') {
                            c=s.charAt(++idx);
                            if (c==='-' || c==="+" || (c>='0' && c<='9')) {
                                c=s.charAt(++idx);
                                while(c>='0' && c<='9') {
                                    c=s.charAt(++idx);
                                }
                            } else {
                                throw "Expected -, 0-9 but found " + c;
                            }
                        }
                        value = Number(s.slice(numStart, idx));
                    } else if (c === 'f' && s.slice(idx-1, idx+4) === 'false') {
                        idx+=4;
                        value=false;
                    } else if (c === 't' && s.slice(idx-1, idx+3) === 'true') {
                        idx+=3;
                        value=true;
                    } else if (c === 'n' && s.slice(idx-1, idx+3) === 'null') {
                        idx+=3;
                        value=null;
                    } else {
                        throw new Error('Bad JSON source');
                    }
            }

            if (! skip) {
                top=stack[stack.length-1];
                if (top is String) {//prop name
                    stack.pop()
                    stack[stack.length-1][top]=value
                } else if (top is Array) {
                    top.push(value)
                } else {
                    //the token must be a prop name
                    stack.push(value);
                }
            }
        }
        return stack[0][0]
    }
}
