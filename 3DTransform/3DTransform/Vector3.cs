using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace _3DTransform {
    public struct Vector3 {
        public double x, y, z;
        public Vector3(double x,double y,double z) {
            this.x = x;
            this.y = y;
            this.z = z;
        }
        public Vector3(Vector3 v) {
            this.x = v.x;
            this.y = v.y;
            this.z = v.z;
        }

        public Vector3(Vector4 v) {
            this.x = v.x;
            this.y = v.y;
            this.z = v.z;
        }

        public static Vector3 operator -(Vector3 a, Vector3 b) {
            return new Vector3(a.x - b.x, a.y - b.y, a.z - b.z);
        }

        public static Vector3 Cross(Vector3 a, Vector3 b) {
            return new Vector3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x);
        }

        public static double Dot(Vector3 a, Vector3 b) {
            return a.x * b.x + a.y * b.y + a.z * b.z;
        }

        public double Magnitude {
            get {
                return Math.Sqrt(x * x + y * y + z * z); 
            }
        }

        public Vector3 Normalised {
            get {
                double mod = Magnitude;
                return new Vector3(x / mod, y / mod, z / mod);
            }
        }
    }
}
