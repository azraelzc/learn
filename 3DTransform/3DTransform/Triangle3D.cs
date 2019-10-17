using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace _3DTransform {
    class Triangle3D {
        private Vector4 a, b, c;
        public Vector4 A, B, C;
        public double dot;
        bool cullBack;
        public Triangle3D () { }
        public Triangle3D (Vector4 a,Vector4 b,Vector4 c) {
            A = this.a = new Vector4(a);
            B = this.b = new Vector4(b);
            C = this.c = new Vector4(c);
        }

        public void Transform(Matrix4x4 m) {
            a = m.Mul(A);
            b = m.Mul(B);
            c = m.Mul(C);
        }

        public void Draw(Graphics g, bool isLine) {
            var points = Get2DPointFArr();
            if (isLine) {
                g.DrawLines(new Pen(Color.Black, 2), points);
            } else {
                if (!cullBack) {
                    GraphicsPath path = new GraphicsPath();
                    path.AddLines(points);
                    int c = (int)(255 * dot);
                    Brush br = new SolidBrush(Color.FromArgb(c, c, c));
                    g.FillPath(br, path);
                }
            }
        }

        private PointF[] Get2DPointFArr() {
            PointF[] arr = new PointF[4];
            arr[0] = Get2DPointF(a);
            arr[1] = Get2DPointF(b);
            arr[2] = Get2DPointF(c);
            arr[3] = arr[0];
            return arr;
        }

        public PointF Get2DPointF(Vector4 v) {
            PointF p = new PointF();
            p.X = (float)(v.x / v.w);
            p.Y = -(float)(v.y / v.w);
            return p;
        }

        public PointF Get2DPointF(Vector3 v) {
            PointF p = new PointF();
            p.X = (float)v.x;
            p.Y = -(float)v.y;
            return p;
        }

        public void CalculateLighting(Matrix4x4 _Object2World,Vector3 L) {
            Transform(_Object2World);
            Vector3 normal = CalculateNormal();
            dot = Vector3.Dot(normal.Normalised, L.Normalised);
            dot = Math.Max(0, dot);
            Vector3 camera = new  Vector3(0, 0, -1);
            cullBack = Vector3.Dot(normal.Normalised, camera) < 0; 
        }

        public Vector3 CalculateNormal() {
            Vector3 U = new Vector3(b) - new Vector3(a);
            Vector3 V = new Vector3(c) - new Vector3(a);
            Vector3 N = Vector3.Cross(U, V);
            return N;
        }
    }
}
