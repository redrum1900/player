package models
{
	import com.pamakids.models.BaseVO;

	public class SongVO extends BaseVO
	{
		public function SongVO()
		{
			super();
		}

		public var url:String;
		public var cover:String;
		public var duration:Number;
		public var name:String;
		public var playTime:Date;
		public var size:Number;
		public var allow_circle:Boolean;
	}
}

