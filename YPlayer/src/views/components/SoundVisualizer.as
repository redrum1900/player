package views.components
{
	import com.pamakids.components.controls.Image;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.BlurFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.media.SoundMixer;
	import flash.utils.ByteArray;
	
	import frocessing.display.F5MovieClip2DBmp;
	
	public class SoundVisualizer extends F5MovieClip2DBmp
	{
		private const Radius:uint = 100;
		private var _circle:Circle;
		private var _count:uint = 0;
		private var w:Number;
		private var h:Number;
		private var cover:Image;
		
		public function SoundVisualizer(width:Number, height:Number)
		{
			w = width;
			h = height;
			_circle = new Circle(0, 128);
			addEventListener(Event.ADDED_TO_STAGE, onStage);
			super(true, 0xd9dee3);
		}
		
		protected function onStage(event:Event):void
		{
			setup();
		}
		
		private var cc:Sprite;
		
		public var pause:Boolean;
		
		public function setCover(url:String):void
		{
			if(!cc){
				cc = new Sprite();
				cc.x = w/2;
				cc.y = h/2;
				addChild(cc);
				var m:Sprite = new Sprite();
				cover = new Image(200, 200);
				cover.x = -100;
				cover.y = -100;
				cover.mask = m;
				cc.addChild(cover);
				m.graphics.beginFill(0);
				m.graphics.drawCircle(0,0,100);
				m.graphics.endFill();
				cc.addChild(m);
				addEventListener(Event.ENTER_FRAME, function(e:Event):void{
					if(pause)
						return;
					cc.rotation += 3;
				});
			}
			cover.source = url;
		}
		
		public function setup():void {
			size(w, h);
			stroke(0x348edf);
			noFill();
			_circle.radius = Radius;
		}
		
		private function updateCircle():void {
			var data:ByteArray = new ByteArray();
			SoundMixer.computeSpectrum(data, true);
			
			var volume:Vector.<Number> = new Vector.<Number>(128);
			for (var i:uint = 0; i<64; i++) {
				volume[i] = 128*Math.sqrt((data.readFloat() + data.readFloat() + data.readFloat() + data.readFloat()) / 4);
			}
			for (var j:uint = 0; j<64; j++) {
				volume[128-j-1] = 128*Math.sqrt((data.readFloat() + data.readFloat() + data.readFloat() + data.readFloat()) / 4);
			}
			
			_circle.update(volume);
		}
		
		public function draw():void {
			if(pause)
				return;
			updateCircle();
			translate( w / 2,  h / 2 );
			
			beginShape();
			for each (var v:Vertex in _circle.vertices) {
				this.curveVertex(v.x, v.y);
			}
			this.curveVertex(_circle.vertices[0].x, _circle.vertices[0].y);
			this.curveVertex(_circle.vertices[1].x, _circle.vertices[1].y);
			this.curveVertex(_circle.vertices[2].x, _circle.vertices[2].y);
			endShape();
			if (_count++ % 3 == 0) {
				bitmapData.colorTransform(bitmapData.rect, new ColorTransform(0, .945, .945, 0.9));
			}
			if (_count % 5 == 0) {
				this.bitmapData.applyFilter(bitmapData, bitmapData.rect, new Point(0, 0), new BlurFilter(4, 4));
			}
		}
	}
}

class Circle {
	private var _vertices:Vector.<Vertex>;
	private var _radius:Number;
	private var _slice:uint;
	
	public function Circle(radius:Number=100, slice:uint=512) {
		_vertices = new Vector.<Vertex>();
		_radius = radius;
		_slice = slice;
		
		var degree:Number = 3*Math.PI/2;
		for (var i:uint = 0; i<slice; i++) {
			_vertices.push(new Vertex(radius, degree));
			degree += 2 * Math.PI / slice;
		}
	}
	
	public function get vertices():Vector.<Vertex> {
		return _vertices;
	}
	
	public function set radius(value:Number):void {
		_radius = value;
		for each (var v:Vertex in _vertices) {
			v.radius = value;
		}
	}
	
	public function update(level:Vector.<Number>):void {
		for (var i:uint=0; i<level.length; i++) {
			if (_vertices[i].radius > _radius + level[i]) {
				_vertices[i].radius = Math.max(_radius, _vertices[i].radius - 5);
			} else {
				_vertices[i].radius = Math.max(_vertices[i].radius, _radius + level[i]);
			}
		}
	}
}

class Vertex {
	private var _radius:Number;
	private var _degree:Number;
	private var _mutable:Boolean;
	
	private var _x:Number;
	private var _y:Number;
	
	public function Vertex(radius:Number, degree:Number, mutable:Boolean=true) {
		_radius = radius;
		_degree = degree;
		_mutable = mutable;
		if (!_mutable) {
			_x = _radius * Math.cos(_degree);
			_y = -_radius * Math.sin(_degree);
		}
	}
	
	public function get x():Number {
		if (_mutable) {
			return _radius * Math.cos(_degree);
		} else {
			return _x;
		}
	}
	
	public function get y():Number {
		if (_mutable) {
			return -_radius * Math.sin(_degree);
		} else {
			return _y;
		}
	}
	
	public function get radius():Number
	{
		return _radius;
	}
	
	public function set radius(value:Number):void
	{
		if (_mutable) {
			_radius = value;
		}
	}
	
	public function get degree():Number
	{
		return _degree;
	}
	
	public function set degree(value:Number):void
	{
		if (_mutable) {
			_degree = value;
		}
	}
}