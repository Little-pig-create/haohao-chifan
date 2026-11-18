<div id="root">
  <div className="app-shell">
    <aside className="sidebar">
      <div className="brand">
        <span className="brand-mark">
          <svg aria-hidden="true" className width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="M20 4c-8.4.2-14 4.1-14 10.1 0 3.2 2.2 5.4 5.2 5.4C17.8 19.5 20 11.3 20 4Z" />
            <path d="M4 21c1.4-5.2 5.2-9 11.4-11.4" />
          </svg>
        </span>
        <span>
          好好吃饭
        </span>
      </div>
      <nav className="sidebar-nav" aria-label="主导航">
        <button className="nav-item">
          <svg aria-hidden="true" className width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="m3 11 9-8 9 8" />
            <path d="M5 10v10h14V10M9 20v-6h6v6" />
          </svg>
          今日菜单
        </button>
        <button className="nav-item">
          <svg aria-hidden="true" className width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <rect x="3" y="5" width="18" height="16" rx="2" />
            <path d="M16 3v4M8 3v4M3 10h18M8 14h.01M12 14h.01M16 14h.01M8 18h.01M12 18h.01" />
          </svg>
          每周计划
        </button>
        <button className="nav-item active">
          <svg aria-hidden="true" className width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="M4 20V10M10 20V4M16 20v-7M22 20H2" />
          </svg>
          营养分析
        </button>
        <button className="nav-item">
          <svg aria-hidden="true" className width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20V4H6.5A2.5 2.5 0 0 0 4 6.5v13Z" />
            <path d="M4 19.5A2.5 2.5 0 0 0 6.5 22H20v-5" />
          </svg>
          健康食谱
        </button>
      </nav>
      <div className="weekly-card">
        <div className="weekly-icon">
          <svg aria-hidden="true" className width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="m12 3 1.2 3.8L17 8l-3.8 1.2L12 13l-1.2-3.8L7 8l3.8-1.2L12 3Z" />
            <path d="m19 14 .7 2.3L22 17l-2.3.7L19 20l-.7-2.3L16 17l2.3-.7L19 14Z" />
          </svg>
        </div>
        <strong>
          本周健康目标
        </strong>
        <p>
          均衡饮食已坚持 4 天
        </p>
        <div className="mini-progress">
          <span style={ width: '57%' }>
          </span>
        </div>
        <small>
          4 / 7 天
        </small>
      </div>
      <button className="profile">
        <span className="avatar">
          林
        </span>
        <span>
          <strong>
            林小满
          </strong>
          <small>
            轻盈生活计划
          </small>
        </span>
        <svg aria-hidden="true" className width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
          <path d="m9 18 6-6-6-6" />
        </svg>
      </button>
    </aside>
    <main className="main-content">
      <section className="feature-page">
        <header className="page-header">
          <div>
            <p className="eyebrow">
              健康数据洞察
            </p>
            <h1>
              营养分析
            </h1>
            <p>
              了解饮食趋势，找到适合你的营养节奏。
            </p>
          </div>
          <div className="period-switch">
            <button className="active">
              本周
            </button>
            <button className>
              本月
            </button>
            <button className>
              三个月
            </button>
          </div>
        </header>
        <div className="analysis-kpis">
          <article>
            <p>
              平均热量
            </p>
            <strong>
              1,826 
              <small>
                千卡 / 天
              </small>
            </strong>
            <span>
              较上期 -3.2%
            </span>
          </article>
          <article>
            <p>
              蛋白质
            </p>
            <strong>
              92 
              <small>
                克 / 天
              </small>
            </strong>
            <span>
              目标完成 97%
            </span>
          </article>
          <article>
            <p>
              饮水量
            </p>
            <strong>
              1.8 
              <small>
                升 / 天
              </small>
            </strong>
            <span>
              较上期 +12%
            </span>
          </article>
          <article>
            <p>
              饮食评分
            </p>
            <strong>
              86 
              <small>
                分
              </small>
            </strong>
            <span>
              优秀
            </span>
          </article>
        </div>
        <div className="analysis-grid">
          <section className="chart-card calorie-chart-card">
            <div className="analysis-card-heading">
              <div>
                <h2>
                  热量摄入趋势
                </h2>
                <p>
                  每日目标 1,850 千卡
                </p>
              </div>
              <span>
                <i>
                </i>
                 实际摄入
              </span>
            </div>
            <div className="bar-chart">
              <div className="bar-column">
                <div className="bar-value">
                  1,332
                </div>
                <div className="bar-track">
                  <span style={ height: '72%' }>
                  </span>
                </div>
                <small>
                  一
                </small>
              </div>
              <div className="bar-column">
                <div className="bar-value">
                  1,554
                </div>
                <div className="bar-track">
                  <span style={ height: '84%' }>
                  </span>
                </div>
                <small>
                  二
                </small>
              </div>
              <div className="bar-column">
                <div className="bar-value">
                  1,443
                </div>
                <div className="bar-track">
                  <span style={ height: '78%' }>
                  </span>
                </div>
                <small>
                  三
                </small>
              </div>
              <div className="bar-column">
                <div className="bar-value">
                  1,721
                </div>
                <div className="bar-track">
                  <span style={ height: '93%' }>
                  </span>
                </div>
                <small>
                  四
                </small>
              </div>
              <div className="bar-column">
                <div className="bar-value">
                  1,591
                </div>
                <div className="bar-track">
                  <span style={ height: '86%' }>
                  </span>
                </div>
                <small>
                  五
                </small>
              </div>
              <div className="bar-column">
                <div className="bar-value">
                  1,258
                </div>
                <div className="bar-track">
                  <span style={ height: '68%' }>
                  </span>
                </div>
                <small>
                  六
                </small>
              </div>
              <div className="bar-column">
                <div className="bar-value">
                  1,499
                </div>
                <div className="bar-track">
                  <span style={ height: '81%' }>
                  </span>
                </div>
                <small>
                  日
                </small>
              </div>
            </div>
          </section>
          <section className="chart-card balance-card">
            <div className="analysis-card-heading">
              <div>
                <h2>
                  营养均衡
                </h2>
                <p>
                  宏量营养素平均占比
                </p>
              </div>
            </div>
            <div className="macro-donut">
              <div>
                <strong>
                  86
                </strong>
                <span>
                  均衡分
                </span>
              </div>
            </div>
            <div className="macro-legend">
              <div>
                <span>
                  <i style={ background: 'rgb(217, 133, 104)' }>
                  </i>
                  蛋白质
                </span>
                <strong>
                  26%
                </strong>
              </div>
              <div>
                <span>
                  <i style={ background: 'rgb(213, 170, 82)' }>
                  </i>
                  碳水
                </span>
                <strong>
                  49%
                </strong>
              </div>
              <div>
                <span>
                  <i style={ background: 'rgb(120, 146, 167)' }>
                  </i>
                  脂肪
                </span>
                <strong>
                  25%
                </strong>
              </div>
            </div>
          </section>
          <section className="chart-card insight-card">
            <div className="analysis-card-heading">
              <div>
                <h2>
                  本周健康洞察
                </h2>
                <p>
                  根据你的饮食记录生成
                </p>
              </div>
            </div>
            <div className="insight-list">
              <article>
                <span>
                  <svg aria-hidden="true" className width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <path d="m5 12 4 4L19 6" />
                  </svg>
                </span>
                <div>
                  <strong>
                    做得很好
                  </strong>
                  <p>
                    蛋白质摄入连续 5 天达标，有助于维持饱腹感。
                  </p>
                </div>
              </article>
              <article>
                <span>
                  <svg aria-hidden="true" className width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M12 2S5 10 5 15a7 7 0 0 0 14 0c0-5-7-13-7-13Z" />
                  </svg>
                </span>
                <div>
                  <strong>
                    可以更好
                  </strong>
                  <p>
                    周末饮水量略低，建议设置每小时饮水提醒。
                  </p>
                </div>
              </article>
              <article>
                <span>
                  <svg aria-hidden="true" className width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M20 4c-8.4.2-14 4.1-14 10.1 0 3.2 2.2 5.4 5.2 5.4C17.8 19.5 20 11.3 20 4Z" />
                    <path d="M4 21c1.4-5.2 5.2-9 11.4-11.4" />
                  </svg>
                </span>
                <div>
                  <strong>
                    下周建议
                  </strong>
                  <p>
                    增加 2 次深色蔬菜，补充叶酸与膳食纤维。
                  </p>
                </div>
              </article>
            </div>
          </section>
        </div>
      </section>
    </main>
  </div>
</div>