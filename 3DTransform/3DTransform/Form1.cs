using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace _3DTransform {
    public partial class Form1 : Form {
        Triangle3D t;
        Cube cube;
        Matrix4x4 m_scale , m_rotationX, m_rotationY, m_rotationZ, m_view, m_projection;
        int a;
        public Form1 () {
            InitializeComponent();

            m_scale = new Matrix4x4();
            m_scale[1, 1] = 250;
            m_scale[2, 2] = 250;
            m_scale[3, 3] = 250;
            m_scale[4, 4] = 1;

            m_rotationX = new Matrix4x4();
            m_rotationY = new Matrix4x4();
            m_rotationZ = new Matrix4x4();

            m_view = new Matrix4x4();
            m_view[1, 1] = 1;
            m_view[2, 2] = 1;
            m_view[3, 3] = 1;
            m_view[4, 3] = 250;
            m_view[4, 4] = 1;
            m_projection = new Matrix4x4();
            m_projection[1, 1] = 1;
            m_projection[2, 2] = 1;
            m_projection[3, 3] = 1;
            m_projection[3, 4] = 1.0 / 250;

            cube = new Cube();
        }

        private void Form1_Load(object sender, EventArgs e) {
            t = new Triangle3D(new Vector4(0, 0.5, 0, 1), new Vector4(0.5, -0.5, 0, 1), new Vector4(-0.5, -0.5, 0, 1));
        }

        private void Form1_Paint(object sender, PaintEventArgs e) {
            e.Graphics.TranslateTransform(300, 300);
            //t.Draw(e.Graphics);
            cube.Draw(e.Graphics,this.line.Checked);
            label1.Text = t.dot.ToString();
        }

        private void timer1_Tick_1(object sender, EventArgs e) {
            a += 2;
            double angle = a / 180.0 * Math.PI;
            //==rotation x axle
            m_rotationX[1, 1] = 1;
            m_rotationX[2, 2] = Math.Cos(angle);
            m_rotationX[2, 3] = Math.Sin(angle);
            m_rotationX[3, 2] = -Math.Sin(angle);
            m_rotationX[3, 3] = Math.Cos(angle);
            m_rotationX[4, 4] = 1;
            //==rotation y axle
            m_rotationY[1, 1] = Math.Cos(angle);
            m_rotationY[1, 3] = Math.Sin(angle);
            m_rotationY[2, 2] = 1;
            m_rotationY[3, 1] = -Math.Sin(angle);
            m_rotationY[3, 3] = Math.Cos(angle);
            m_rotationY[4, 4] = 1;
            //==rotation z axle
            m_rotationZ[1, 1] = Math.Cos(angle);
            m_rotationZ[1, 2] = Math.Sin(angle);
            m_rotationZ[2, 1] = -Math.Sin(angle);
            m_rotationZ[2, 2] = Math.Cos(angle);
            m_rotationZ[3, 3] = 1;
            m_rotationZ[4, 4] = 1;

            if(rotationX.Checked) {
                Matrix4x4 tx = m_rotationX.Transpose();
                m_rotationX = m_rotationX.Mul(tx);
            }
            if(rotationY.Checked) {
                Matrix4x4 ty = m_rotationY.Transpose();
                m_rotationY= m_rotationY.Mul(ty);
            }
            if(rotationZ.Checked) {
                Matrix4x4 tz = m_rotationZ.Transpose();
                m_rotationZ = m_rotationZ.Mul(tz);
            }

            //lesson10+
            Matrix4x4 mall = m_rotationX.Mul(m_rotationY).Mul(m_rotationZ);
            //Matrix4x4 m = m_scale.Mul(m_rotationX).Mul(m_rotationY).Mul(m_rotationZ).Mul(m_view).Mul(m_projection);
            Matrix4x4 m = m_scale.Mul(mall);
            //t.CalculateLighting(m, new Vector3(-1,1,-1));
            cube.CalculateLighting(m, new Vector3(-1, 1, -1));
            Matrix4x4 mv = m.Mul(m_view);
            Matrix4x4 mvp = mv.Mul(m_projection);
            //t.Transform(mvp);
            cube.Transform(mvp);
            this.Invalidate();
        }


        private void trackBar1_Scroll(object sender, EventArgs e) {
            m_view[4, 3] = (sender as TrackBar).Value;
        }

        private void checkBox1_CheckedChanged(object sender, EventArgs e) {

        }

        private void checkBox2_CheckedChanged(object sender, EventArgs e) {

        }

        private void checkBox3_CheckedChanged(object sender, EventArgs e) {

        }
    }
}
