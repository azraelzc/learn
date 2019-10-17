namespace _3DTransform {
    partial class Form1 {
        /// <summary>
        /// 必需的设计器变量。
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// 清理所有正在使用的资源。
        /// </summary>
        /// <param name="disposing">如果应释放托管资源，为 true；否则为 false。</param>
        protected override void Dispose (bool disposing) {
            if(disposing && (components != null)) {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows 窗体设计器生成的代码

        /// <summary>
        /// 设计器支持所需的方法 - 不要修改
        /// 使用代码编辑器修改此方法的内容。
        /// </summary>
        private void InitializeComponent () {
            this.components = new System.ComponentModel.Container();
            this.timer1 = new System.Windows.Forms.Timer(this.components);
            this.trackBar1 = new System.Windows.Forms.TrackBar();
            this.rotationX = new System.Windows.Forms.CheckBox();
            this.rotationY = new System.Windows.Forms.CheckBox();
            this.rotationZ = new System.Windows.Forms.CheckBox();
            this.label1 = new System.Windows.Forms.Label();
            this.line = new System.Windows.Forms.CheckBox();
            ((System.ComponentModel.ISupportInitialize)(this.trackBar1)).BeginInit();
            this.SuspendLayout();
            // 
            // timer1
            // 
            this.timer1.Enabled = true;
            this.timer1.Interval = 40;
            this.timer1.Tick += new System.EventHandler(this.timer1_Tick_1);
            // 
            // trackBar1
            // 
            this.trackBar1.Location = new System.Drawing.Point(125, 21);
            this.trackBar1.Maximum = 1000;
            this.trackBar1.Minimum = 250;
            this.trackBar1.Name = "trackBar1";
            this.trackBar1.Size = new System.Drawing.Size(236, 45);
            this.trackBar1.TabIndex = 0;
            this.trackBar1.Value = 250;
            this.trackBar1.Scroll += new System.EventHandler(this.trackBar1_Scroll);
            // 
            // rotationX
            // 
            this.rotationX.AutoSize = true;
            this.rotationX.Location = new System.Drawing.Point(387, 21);
            this.rotationX.Name = "rotationX";
            this.rotationX.Size = new System.Drawing.Size(78, 16);
            this.rotationX.TabIndex = 1;
            this.rotationX.Text = "rotationX";
            this.rotationX.UseVisualStyleBackColor = true;
            this.rotationX.CheckedChanged += new System.EventHandler(this.checkBox1_CheckedChanged);
            // 
            // rotationY
            // 
            this.rotationY.AutoSize = true;
            this.rotationY.Location = new System.Drawing.Point(387, 49);
            this.rotationY.Name = "rotationY";
            this.rotationY.Size = new System.Drawing.Size(78, 16);
            this.rotationY.TabIndex = 2;
            this.rotationY.Text = "rotationY";
            this.rotationY.UseVisualStyleBackColor = true;
            this.rotationY.CheckedChanged += new System.EventHandler(this.checkBox2_CheckedChanged);
            // 
            // rotationZ
            // 
            this.rotationZ.AutoSize = true;
            this.rotationZ.Location = new System.Drawing.Point(387, 72);
            this.rotationZ.Name = "rotationZ";
            this.rotationZ.Size = new System.Drawing.Size(78, 16);
            this.rotationZ.TabIndex = 3;
            this.rotationZ.Text = "rotationZ";
            this.rotationZ.UseVisualStyleBackColor = true;
            this.rotationZ.CheckedChanged += new System.EventHandler(this.checkBox3_CheckedChanged);
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(508, 24);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(41, 12);
            this.label1.TabIndex = 4;
            this.label1.Text = "label1";
            // 
            // line
            // 
            this.line.AutoSize = true;
            this.line.Location = new System.Drawing.Point(387, 94);
            this.line.Name = "line";
            this.line.Size = new System.Drawing.Size(48, 16);
            this.line.TabIndex = 5;
            this.line.Text = "line";
            this.line.UseVisualStyleBackColor = true;
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 12F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(584, 562);
            this.Controls.Add(this.line);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.rotationZ);
            this.Controls.Add(this.rotationY);
            this.Controls.Add(this.rotationX);
            this.Controls.Add(this.trackBar1);
            this.Name = "Form1";
            this.Text = "Form1";
            this.Load += new System.EventHandler(this.Form1_Load);
            this.Paint += new System.Windows.Forms.PaintEventHandler(this.Form1_Paint);
            ((System.ComponentModel.ISupportInitialize)(this.trackBar1)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Timer timer1;
        private System.Windows.Forms.TrackBar trackBar1;
        private System.Windows.Forms.CheckBox rotationX;
        private System.Windows.Forms.CheckBox rotationY;
        private System.Windows.Forms.CheckBox rotationZ;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.CheckBox line;
    }
}

