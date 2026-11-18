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
        <button className="nav-item active">
          <svg aria-hidden="true" className width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <rect x="3" y="5" width="18" height="16" rx="2" />
            <path d="M16 3v4M8 3v4M3 10h18M8 14h.01M12 14h.01M16 14h.01M8 18h.01M12 18h.01" />
          </svg>
          每周计划
        </button>
        <button className="nav-item">
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
              9月16日 — 9月22日
            </p>
            <h1>
              每周饮食计划
            </h1>
            <p>
              提前安排一周三餐，让健康饮食变得简单而有序。
            </p>
          </div>
          <button className="primary-action">
            <svg aria-hidden="true" className width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
              <path d="m5 12 4 4L19 6" />
            </svg>
            生成采购清单
          </button>
        </header>
        <div className="week-summary-grid">
          <article className="summary-tile">
            <span className="summary-icon tone-1">
              <svg aria-hidden="true" className width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <rect x="3" y="5" width="18" height="16" rx="2" />
                <path d="M16 3v4M8 3v4M3 10h18M8 14h.01M12 14h.01M16 14h.01M8 18h.01M12 18h.01" />
              </svg>
            </span>
            <div>
              <p>
                本周计划
              </p>
              <strong>
                21 
                <small>
                  餐
                </small>
              </strong>
            </div>
          </article>
          <article className="summary-tile">
            <span className="summary-icon tone-2">
              <svg aria-hidden="true" className width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <path d="M12 22c4.4 0 7-3.2 7-7.3 0-3.2-2-6.4-5-9.7-.5 3-2 4.2-3 5.5-.7-2-1.8-3.7-3.4-5C6.4 9 5 11.5 5 15c0 4 2.7 7 7 7Z" />
              </svg>
            </span>
            <div>
              <p>
                日均热量
              </p>
              <strong>
                1,826 
                <small>
                  千卡
                </small>
              </strong>
            </div>
          </article>
          <article className="summary-tile">
            <span className="summary-icon tone-3">
              <svg aria-hidden="true" className width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <path d="M4 20V10M10 20V4M16 20v-7M22 20H2" />
              </svg>
            </span>
            <div>
              <p>
                蛋白质达标
              </p>
              <strong>
                6 
                <small>
                  / 7 天
                </small>
              </strong>
            </div>
          </article>
          <article className="summary-tile">
            <span className="summary-icon tone-4">
              <svg aria-hidden="true" className width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <path d="M20 4c-8.4.2-14 4.1-14 10.1 0 3.2 2.2 5.4 5.2 5.4C17.8 19.5 20 11.3 20 4Z" />
                <path d="M4 21c1.4-5.2 5.2-9 11.4-11.4" />
              </svg>
            </span>
            <div>
              <p>
                食材种类
              </p>
              <strong>
                32 
                <small>
                  种
                </small>
              </strong>
            </div>
          </article>
        </div>
        <div className="weekly-planner">
          <div className="planner-days">
            <button className>
              <span>
                周一
              </span>
              <strong>
                16
              </strong>
              <i>
                已计划
              </i>
            </button>
            <button className>
              <span>
                周二
              </span>
              <strong>
                17
              </strong>
              <i>
                已计划
              </i>
            </button>
            <button className>
              <span>
                周三
              </span>
              <strong>
                18
              </strong>
              <i>
                已计划
              </i>
            </button>
            <button className="active">
              <span>
                周四
              </span>
              <strong>
                19
              </strong>
              <i>
                已计划
              </i>
            </button>
            <button className>
              <span>
                周五
              </span>
              <strong>
                20
              </strong>
              <i>
                待完成
              </i>
            </button>
            <button className>
              <span>
                周六
              </span>
              <strong>
                21
              </strong>
              <i>
                待完成
              </i>
            </button>
            <button className>
              <span>
                周日
              </span>
              <strong>
                22
              </strong>
              <i>
                待完成
              </i>
            </button>
          </div>
          <div className="day-plan">
            <div className="day-plan-heading">
              <div>
                <p>
                  9月19日 · 周四
                </p>
                <h2>
                  今日三餐
                </h2>
              </div>
              <span>
                约 1,820 千卡
              </span>
            </div>
            <div className="plan-meals">
              <article>
                <img alt="菠菜蘑菇欧姆蛋" src="https://images.unsplash.com/photo-1629793982045-5f847bd65a61?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=800&h=600" />
                <div>
                  <span>
                    早餐 · 08:00
                  </span>
                  <h3>
                    菠菜蘑菇欧姆蛋
                  </h3>
                  <p>
                    420 千卡 · 蛋白质 23g
                  </p>
                </div>
                <button aria-label="替换菠菜蘑菇欧姆蛋">
                  <svg aria-hidden="true" className width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M20 7v5h-5" />
                    <path d="M4 17v-5h5M18.3 9A7 7 0 0 0 6.4 6.4L4 9M5.7 15A7 7 0 0 0 17.6 17.6L20 15" />
                  </svg>
                </button>
              </article>
              <article>
                <img alt="日式鳗鱼杂粮饭" src="https://images.unsplash.com/photo-1543352634-a1c51d9f1fa7?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=800&h=600" />
                <div>
                  <span>
                    午餐 · 12:30
                  </span>
                  <h3>
                    日式鳗鱼杂粮饭
                  </h3>
                  <p>
                    680 千卡 · 蛋白质 42g
                  </p>
                </div>
                <button aria-label="替换日式鳗鱼杂粮饭">
                  <svg aria-hidden="true" className width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M20 7v5h-5" />
                    <path d="M4 17v-5h5M18.3 9A7 7 0 0 0 6.4 6.4L4 9M5.7 15A7 7 0 0 0 17.6 17.6L20 15" />
                  </svg>
                </button>
              </article>
              <article>
                <img alt="菌菇豆腐汤" src="https://images.unsplash.com/photo-1580683750935-cecfc7ea57f0?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=800&h=600" />
                <div>
                  <span>
                    晚餐 · 18:30
                  </span>
                  <h3>
                    菌菇豆腐汤
                  </h3>
                  <p>
                    530 千卡 · 蛋白质 21g
                  </p>
                </div>
                <button aria-label="替换菌菇豆腐汤">
                  <svg aria-hidden="true" className width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M20 7v5h-5" />
                    <path d="M4 17v-5h5M18.3 9A7 7 0 0 0 6.4 6.4L4 9M5.7 15A7 7 0 0 0 17.6 17.6L20 15" />
                  </svg>
                </button>
              </article>
            </div>
            <div className="plan-note">
              <svg aria-hidden="true" className width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <path d="m12 3 1.2 3.8L17 8l-3.8 1.2L12 13l-1.2-3.8L7 8l3.8-1.2L12 3Z" />
                <path d="m19 14 .7 2.3L22 17l-2.3.7L19 20l-.7-2.3L16 17l2.3-.7L19 14Z" />
              </svg>
              <p>
                <strong>
                  搭配建议
                </strong>
                 今日膳食纤维充足，晚餐后可搭配一小杯无糖酸奶。
              </p>
            </div>
          </div>
        </div>
      </section>
    </main>
  </div>
</div>