package models
{
	import com.pamakids.models.BaseVO;

	public class InsertVO extends BaseVO
	{
		public static const CUSTOMIZE_BRO:int=1;
		public static const CUSTOMIZE_INSERT:int=2;
		public static const AUTO_INSERT:int=5;

		public function InsertVO()
		{
			super();
		}

		public var url:String;
		public var name:String;
		public var playTime:Date;
		public var repeat:int;
		public var interval:int;
		public var duration:Number;
		public var type:int;
		public var size:Number;
		public var tags:String;
	}
}

