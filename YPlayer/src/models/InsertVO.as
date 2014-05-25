package models
{
	import com.pamakids.models.BaseVO;

	public class InsertVO extends BaseVO
	{
		public function InsertVO()
		{
			super();
		}

		public var url:String;
		public var name:String;
		public var playTime:String;
		public var repeat:int;
		public var interval:int;
	}
}

