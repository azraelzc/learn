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
        Matrix4x4 m_scale;
        Matrix4x4 m_rotation;
        Matrix4x4 m_view;
        Matrix4x4 m_projection;
        int a;
        public Form1 () {
            InitializeComponent();

            m_scale = new Matrix4x4();
            m_scale[1, 1] = 250;
            m_scale[2, 2] = 250;
            m_scale[3, 3] = 250;
            m_scale[4, 4] = 1;

            m_rotation = new Matrix4x4();

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
        }

        private void Form1_Load(object sender, EventArgs e) {
            t = new Triangle3D(new Vector4(0, -0.5, 0, 1), new Vector4(0.5, 0.5, 0, 1), new Vector4(-0.5, 0.5, 0, 1));
            

        }

        private void Form1_Paint(object sender, PaintEventArgs e) {
            t.Draw(e.Graphics);
        }

        private void timer1_Tick_1(object sender, EventArgs e) {
            a += 2;
            double angle = a / 360.0 * Math.PI;
            m_rotation[1, 1] = Math.Cos(angle);
            m_rotation[1, 3] = Math.Sin(angle);
            m_rotation[2, 2] = 1;
            m_rotation[3, 1] = -Math.Sin(angle);
            m_rotation[3, 3] = Math.Cos(angle);
            m_rotation[4, 4] = 1;
            Matrix4x4 m = m_scale.Mul(m_rotation).Mul(m_view).Mul(m_projection);
            t.Trasform(m);
            this.Invalidate();
        }
    }
}
