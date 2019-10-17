using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace _3DTransform {
    public struct Vector4 {
        public double x, y, z, w;
        public Vector4(double x,double y,double z,double w) {
            this.x = x;
            this.y = y;
            this.z = z;
            this.w = w;
        }
        public Vector4(Vector4 v) {
            this.x = v.x;
            this.y = v.y;
            this.z = v.z;
            this.w = v.w;
        }

        public Vector4(Vector3 v) {
            this.x = v.x;
            this.y = v.y;
            this.z = v.z;
            this.w = 0;
        }

        public static Vector4 operator -(Vector4 a, Vector4 b) {
            return new Vector4(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w);
        }
    }
}
