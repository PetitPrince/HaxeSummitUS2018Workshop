
import luxe.GameConfig;
import luxe.Input;
import luxe.Color;
import luxe.tween.Actuate;
import haxe.*;
import mp.Command;
import mp.Message;
import game.*;

using Lambda;

class Main extends luxe.Game {
    
    var world:World;
    var state:GameState;
    var connected = false;
    var id:Null<Int>;
    var mp:Bool = true;
    var ws:haxe.net.WebSocket;

    override function config(config:GameConfig) {

        config.window.title = 'luxe game';
        config.window.width = 960;
        config.window.height = 640;
        config.window.fullscreen = false;

        return config;

    } //config

    override function ready() {
        if(mp) {
            ws = haxe.net.WebSocket.create("ws://127.0.0.1:8888", ['echo-protocol'], false);
            ws.onopen = function() ws.sendString(Serializer.run(Join));
            ws.onmessageString = function(msg) {
                var msg:Message = Unserializer.run(msg);
                switch msg {
                    case Joined(id): this.id = id;
                    case State(state): this.state = state;
                }
            }
        } else {
            world = new World();
            id = world.createPlayer().id;
        }
            
    } //ready

    override function onkeyup(event:KeyEvent) {

        if(event.keycode == Key.escape) {
            Luxe.shutdown();
        }

    } //onkeyup

    override function update(delta:Float) {
        if(mp) {
            ws.process();
            if(state == null) return; // not ready
        } else {
            state = world.update();
        }
        
        // handle move
        var player = state.objects.find(function(o) return o.id == id);
        if(player == null) {
            id = null;
        } else {
            // move player
            var mid = Luxe.screen.mid;
            if(touched) {
                var cursor = Luxe.screen.cursor.pos;
                var dir = Math.atan2(cursor.y - mid.y, cursor.x - mid.x);
                if(mp) {
                    if(player.speed == 0) ws.sendString(Serializer.run(StartMove));
                    ws.sendString(Serializer.run(SetDirection(dir)));
                } else {
                    player.speed = 3;
                    player.dir = dir;
                }
            } else {
                if(mp) {
                    if(player.speed != 0) ws.sendString(Serializer.run(StopMove));
                } else {
                    player.speed = 0;
                }
            }
            
            // update camera
            var scale = player.size / 40;
            Actuate.tween(Luxe.camera.scale, 0.2, {x: scale, y: scale});
            Luxe.camera.pos.set_xy(player.x - mid.x, player.y - mid.y);
        }
        
        draw(state.objects);
    } //update
    
    var touched:Bool = false;
    override function onmousedown(e) {
        touched = true;
    }
    
    override function onmouseup(e) {
        touched = false;
        
    }
    override function ontouchdown(e) {
        touched = true;
    }
    
    override function ontouchup(e) {
        touched = false;
        
    }
    
    function draw(objects:Array<Object>) {
        for(object in objects) {
            Luxe.draw.circle({
                x: object.x,
                y: object.y,
                r: object.size, 
                color: new Color().rgb(object.color),
                immediate: true, // should use a sprite/visual
                depth: object.depth,
            });
        }
    }

} //Main
