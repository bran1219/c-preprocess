var svg_doc;
var $svg;
var colDic;
var col2Dic;
var edgesDic;
var nodesDic;

$(function(){
    // $(document).ajaxSuccess();
    // $("#svg1").load("./gvt.svg", "", getSVG);
    // $("#svg1").load("file:///D:/oss/gvt.svg", "", getSVG);
    $("#but1").on("click", but1_click);
    $("#but2").click(getSVG);
    $("#but2").click(addNodeEventHandler);
    $("#svg1").on("load", getSVG);
    $("#svg1").on("load", addNodeEventHandler);
    $("#but3").click(but3_click);
    $("#but4").click(but4_click);
    $( "#floatmenu" ).draggable();
    $( "#info" ).draggable();
    var mes = "Loading..."+
    "ノードをクリックすると情報表示します。"+
    "ノードをダブルクリックすると非表示になります。"+
    "エッジをクリックすると色が変わります。"+
    "エッジをダブルクリックすると、端点ノードに移動します。"
    $("#info").css("color","red");
    $("#info").css("border","1px dotted #000000");
    $("#info").css("width","500px");
    $("#info").css("position","absolute");
    $("#info").html(mes);
    // $('#floatmenu').portamento();
});

function getSVG(responseText, textStatus, xhr) {
    // contentDocument does not work in chrome
    svg_doc = document.getElementById('svg1').contentDocument;
    // svg_doc = document.getElementById('svg1').contentWindow.document;
    $svg = $(svg_doc).find('svg');
    // addNodeEventHandler();
    colDic = { "black":"red", "red":"blue", "blue":"green", "green":"purple", "purple":"brown", "brown":"pink", "pink":"black" };
    // col2Dic = { "black":"white", "white":"black" };
}

function but1_click(){
    console.log("but1_click");
    // getSVG();
    // addNodeEventHandler();
    nodeVisible($("#trg1"));
}

function nodeVisible($tgt){
    // show or hide matched nodes
    var nodestr = $tgt.val();
    console.log("nodeVisible "+ nodestr );
    var tgs = $svg.find("g.node");
    var nodes=[];
    var re1 = new RegExp("^"+nodestr);
    var re2 = new RegExp(nodestr+"$");
    var re3 = new RegExp(nodestr);
    for (var i=0; i<tgs.length; i++){
        var tmpStr = $(tgs[i]).find("text").text();
        var tmpStr2 = $(tgs[i]).find("title").text();
        if (re1.test(tmpStr) || re2.test(tmpStr) || re3.test(tmpStr2)){
            nodes.push($(tgs[i]));
            // console.log("1:" + $(tgs[i]).text());
        }
        // if (nodes.length == 0){
        //     if (re3.test(tmpStr)){
        //         nodes.push($(tgs[i]));
        //         console.log("2:" + $(tgs[i]).text());
        //     }
        // }
    }
    // console.log($("#act1").val() +" "+ tgs.length);
    if ($("#act1").val() == "visible"){
        for (var i=0; i<nodes.length; i++){
            nodes[i].show();
        }
        for (var i=0; i<nodes.length; i++){
            var edges = edgesDic[nodes[i].find("title").text()];
            for (var i2=0; i2<edges.length; i2++){
                var tmpAry = edges[i2].find("title").text().split("->");
                if (nodesDic[tmpAry[0]].css("display") == "inline" && nodesDic[tmpAry[1]].css("display") == "inline"){
                    edges[i2].show();
                }
            }
        }
    }
    else{
        for (var i=0; i<nodes.length; i++){
            nodes[i].hide();
            edges = edgesDic[nodes[i].find("title").text()];
            for (var i2=0; i2<edges.length; i2++){
                edges[i2].hide();
            }
        }
    }
}

function but3_click(){
    // all
    console.log("but3_click");
    var tges = $svg.find("g.edge");
    if ($("#act1").val() == "visible"){
        for (i in nodesDic){
            // console.log(i);
            nodesDic[i].show();
        } 
        for (var i2=0; i2<tges.length; i2++){
            $(tges[i2]).show();
        }
    }
    else{
        for (var i in nodesDic){
            // console.log(i);
            nodesDic[i].hide();
        } 
        for (var i2=0; i2<tges.length; i2++){
            $(tges[i2]).hide();
        }
    }
}

function but4_click(){
    // search
    var tstr = $("#trg1").val();
    console.log("but4_click " + tstr);
    if (nodesDic[tstr]){
        $("html,body").animate({scrollLeft:nodesDic[tstr].offset().left, scrollTop:nodesDic[tstr].offset().top});
        nodesDic[tstr].attr("fill", "blue");
        return;
    }
    var re1 = new RegExp(tstr);
    // var re1 = new RegExp(".*"+tstr+".*");
    // var re2 = new RegExp(tstr+"$");
    // var re3 = new RegExp(tstr);
    for (var i in nodesDic){
        // console.log(i+" "+nodesDic[i].find("text").text());
        //  || re2.test(nodesDic[i].text()) || re3.test(nodesDic[i].text())
        if (re1.test(nodesDic[i].text())){
            $("html,body").animate({scrollLeft:nodesDic[i].offset().left, scrollTop:nodesDic[i].offset().top});
            nodesDic[i].attr("fill", "purple");
            return;
        }
    } 
}

function addNodeEventHandler(){
    var tgs = $svg.find("g.node");
    var tges = $svg.find("g.edge");
    edgesDic = {};
    nodesDic = {};
    for (var i=0; i<tgs.length; i++){
        // $(tgs[i]).off("click");
        $(tgs[i]).on("click", null, { node:$(tgs[i]), id:$(tgs[i]).attr("id"), title:$(tgs[i]).find("title").text(), stroke:$(tgs[i]).find("path").attr("stroke") }, node_click);
        $(tgs[i]).on("dblclick", null, { node:$(tgs[i]), id:$(tgs[i]).attr("id"), title:$(tgs[i]).find("title").text(), stroke:$(tgs[i]).find("path").attr("stroke") }, node_dblclick);
        $(tgs[i]).on("mouseenter", null, { node:$(tgs[i]), id:$(tgs[i]).attr("id"), title:$(tgs[i]).find("title").text(), stroke:$(tgs[i]).find("path").attr("stroke") }, node_enter);
        // $(tgs[i]).on("mouseleave", null, { node:$(tgs[i]), id:$(tgs[i]).attr("id"), title:$(tgs[i]).find("title").text(), stroke:$(tgs[i]).find("path").attr("stroke") }, node_leave);
        edgesDic[$(tgs[i]).find("title").text()] = [];
        nodesDic[$(tgs[i]).find("title").text()] = $(tgs[i]);
    }
    for (var i2 = 0; i2 < tges.length; i2++) {
        $(tges[i2]).on("click", null, { edge:$(tges[i2]), id:$(tges[i2]).attr("id"), title:$(tges[i2]).find("title").text(), stroke:$(tges[i2]).find("path").attr("stroke") }, edge_click);
        $(tges[i2]).on("dblclick", null, { edge:$(tges[i2]), id:$(tges[i2]).attr("id"), title:$(tges[i2]).find("title").text(), stroke:$(tges[i2]).find("path").attr("stroke") }, edge_dblclick);
        var tmpText = $(tges[i2]).find("title").text();
        // console.log(tmpText);
        var tmpAry = tmpText.split("->");
        edgesDic[tmpAry[0]].push($(tges[i2]));
        edgesDic[tmpAry[1]].push($(tges[i2]));
    }
    console.log("addNodeEventHandler end");
    $("#info").html("Load completed");
}

function node_enter(event){
    console.log("node_click "+ event.data.id +":" +event.data.title);
    var tcol = colDic[event.data.node.attr("fill")];
    if (tcol == undefined){
        tcol = "red";
    }
    event.data.node.attr("fill", tcol);
    event.data.node.find("polygon").attr("stroke", tcol);
    for (var i=0; i<edgesDic[event.data.title].length; i++){
        edgesDic[event.data.title][i].find("path").attr("stroke", tcol);
        edgesDic[event.data.title][i].find("polygon").attr("stroke", tcol);
        edgesDic[event.data.title][i].find("polygon").attr("fill", tcol);
    }
    
}

function node_click(event){
    // console.log("node_enter "+ event.data.id +":" +event.data.title);
    var callers = ""; // call this node
    var callees = ""; // called from this node
    var callerCnt = 0; // call this node
    var calleeCnt = 0; // called from this node
    var $node;
    var tmp;
    for (var i=0; i<edgesDic[event.data.title].length; i++){
        var $edge = edgesDic[event.data.title][i];
        var tmpAry = $edge.find("title").text().split("->");
        var from = tmpAry[0];
        var to = tmpAry[1];
        if (from == event.data.title){
            $node = nodesDic[to];
            calleeCnt++;
            // callees += to + "=" + $node.find("text").html() + "<br>";
            // tmp = $node.text().split("\n");
            // callees += tmp[0] + " " + tmp[2] + "<br>";
           callees += $node.text() + "<br>";
        }
        if (to == event.data.title){
            $node = nodesDic[from];
            callerCnt++;
            // callers += from + "=" + $node.find("text").html() + "<br>";
            // tmp = $node.text().split("\n");
            // callers += tmp[0] + " " + tmp[2] + "<br>";
            callers += $node.text() + "<br>";
        }
    }
    var x0 = event.data.node.offset().left; // -$("#info").width()/2;
    var y0 = event.data.node.offset().top;  //-$("#info").height()/2;
    var x1 = x0 - $(window).width()/2;
    var y1 = y0 - $(window).height()/2;
    // var x0 = event.data.node.position().left;
    // var y0 = event.data.node.position().top;
    // $("#info").css("left",x0);
    // $("#info").css("top",y0);
    $("#info").html(event.data.node.find("title").text() + "<br>" + callers + callerCnt + "<br><br>" + callees + calleeCnt);
    $("#info").offset({top:y0, left:x0});
    $("html,body").animate({scrollLeft:x1, scrollTop:y1});
}

function node_leave(event){
    // console.log("node_leave "+ event.data.id +":" +event.data.title);
    // $("#info").html("");
}

function node_dblclick(event){
    console.log("node_dblclick "+ event.data.id +":" +event.data.title);
    event.data.node.hide();
    for (var i=0; i<edgesDic[event.data.title].length; i++){
        edgesDic[event.data.title][i].hide();
    }

    // tcol = colDic[event.data.node.find("polygon").attr("stroke")];
    // event.data.node.find("polygon").attr("stroke", tcol);
    // textary = event.data.node.find("text");
    // for (i=0; i<textary.length; i++){
    //     textary[i].attr("color", tcol);
    // }
    // for (i=0; i<edgesDic[event.data.title].length; i++){
    //     edgesDic[event.data.title][i].find("path").attr("stroke", tcol);
    //     edgesDic[event.data.title][i].find("polygon").attr("stroke", tcol);
    //     edgesDic[event.data.title][i].find("polygon").attr("fill", tcol);
    // }
}

function node_click2(node, title){
    console.log("node_click "+title);
    node.fadeIn();
    for (var i=0; i<edgesDic[title].length; i++){
        edgesDic[title][i].fadeIn();
    }
}

function edge_click(event){
    console.log("edge_click "+ event.data.id +":" +event.data.title +":" +event.data.edge.find("path").attr("stroke"));
    var tcol = colDic[event.data.edge.find("path").attr("stroke")];
    // console.log("edge_click "+ colDic[event.data.edge.find("path").attr("stroke")] +" -> " + tcol);
    // event.data.edge.hide();
    event.data.edge.find("path").attr("stroke", tcol);
    event.data.edge.find("polygon").attr("stroke", tcol);
    event.data.edge.find("polygon").attr("fill", tcol);
    // event.data.edge.find("path")[0].setAttribute("stroke", "red");
}

function edge_dblclick(event){
    console.log("edge_dblclick "+ event.data.id +":" +event.data.title +":" +event.data.edge.find("path").attr("stroke"));
    var tmpText = event.data.edge.find("title").text();
    // console.log(tmpText);
    var tmpAry = tmpText.split("->");
    // $("html,body").animate({scrollTop:nodesDic[tmpAry[0]].offset().top()});
    var x0 = nodesDic[tmpAry[0]].offset().left;
    var y0 = nodesDic[tmpAry[0]].offset().top;
    var x1 = nodesDic[tmpAry[1]].offset().left;
    var y1 = nodesDic[tmpAry[1]].offset().top;
    if (Math.pow(event.pageX-x0,2)+Math.pow(event.pageY-y0,2) > Math.pow(event.pageX-x1,2)+Math.pow(event.pageY-y1,2)){
        $("html,body").animate({scrollLeft:x0 - $(window).width()/2, scrollTop:y0 - $(window).height()/2});
        nodesDic[tmpAry[0]].attr("fill", "blue");
    }
    else{
        $("html,body").animate({scrollLeft:x1 - $(window).width()/2, scrollTop:y1 - $(window).height()/2});
        nodesDic[tmpAry[1]].attr("fill", "blue");
    }
}


function edgeVisible(tstr, visiblesw){
    console.log("edgeVisible "+ tstr +":" +visiblesw);
    var re1 = new RegExp("^"+tstr);
    var re2 = new RegExp(tstr+"$");
    var tgs = $svg.find("g.edge");
    if (visiblesw == "visible"){
        for (var i = 0; i < tgs.length; i++) {
            var tmpText = $(tgs[i]).find("title").text();
            // console.log(tmpText);
            if (re1.test(tmpText) || re2.test(tmpText)) {
                $(tgs[i]).fadeIn();
            }
        }
    }
    else{
        for (i = 0; i < tgs.length; i++) {
            tmpText = $(tgs[i]).find("title").text();
            // console.log(tmpText);
            if (re1.test(tmpText) || re2.test(tmpText)) {
                $(tgs[i]).hide();
            }
        }
    }
}
