using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Drawing;

namespace MatrixTransform {
    class Triangle {
        PointF A, B, C;
        public Triangle (PointF A, PointF B, PointF C) {
            this.A = A;
            this.B = B;
            this.C = C;
        }

        public void Draw (Graphics g) {
            Pen pen = new Pen(Color.Red,2);
            g.DrawLine(pen, A, B);
            g.DrawLine(pen, B, C);
            g.DrawLine(pen, C, A);
        }

        public void Rotate (float angle) {
            float rotation = (float)(angle / 360f * Math.PI);
            RotatePoint(ref A, rotation);
            RotatePoint(ref B, rotation);
            RotatePoint(ref C, rotation);
        }

        void RotatePoint (ref PointF p, float rotation) {
            float newX = (float)(p.X * Math.Cos(rotation) - p.Y * Math.Sin(rotation));
            float newY = (float)(p.X * Math.Sin(rotation) + p.Y * Math.Cos(rotation));
            p.X = newX;
            p.Y = newY;
        }

        public void Scale (float scaleX, float scaleY) {
            ScalePoint(ref A, scaleX, scaleY);
            ScalePoint(ref B, scaleX, scaleY);
            ScalePoint(ref C, scaleX, scaleY);
        }

        void ScalePoint (ref PointF p, float scaleX, float scaleY) {
            p.X = p.X * scaleX;
            p.Y = p.Y * scaleY;
        }
    }
}
