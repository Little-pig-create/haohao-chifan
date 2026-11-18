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
        <button className="nav-item">
          <svg aria-hidden="true" className width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="M4 20V10M10 20V4M16 20v-7M22 20H2" />
          </svg>
          营养分析
        </button>
        <button className="nav-item active">
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
        <header className="page-header recipe-page-header">
          <div>
            <p className="eyebrow">
              精选健康灵感
            </p>
            <h1>
              健康食谱
            </h1>
            <p>
              简单、营养、美味，每一餐都值得期待。
            </p>
          </div>
          <label className="recipe-search">
            <svg aria-hidden="true" className width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="11" cy="11" r="7" />
              <path d="m20 20-4-4" />
            </svg>
            <input placeholder="搜索食谱..." value />
          </label>
        </header>
        <div className="recipe-filters">
          <button className="active">
            全部
          </button>
          <button className>
            早餐
          </button>
          <button className>
            高蛋白
          </button>
          <button className>
            低脂
          </button>
          <button className>
            素食
          </button>
          <button className>
            已收藏
          </button>
        </div>
        <div className="recipe-featured">
          <div>
            <span>
              本周推荐
            </span>
            <h2>
              用一碗彩虹，
              <br />
              唤醒身体的能量
            </h2>
            <p>
              12 种天然食材，提供丰富的膳食纤维与优质蛋白。20 分钟就能完成。
            </p>
            <button>
              加入我的菜单 
              <svg aria-hidden="true" className width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <path d="m9 18 6-6-6-6" />
              </svg>
            </button>
          </div>
          <img alt="彩虹能量碗" src="https://images.unsplash.com/photo-1543352634-a1c51d9f1fa7?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=800&h=600" />
        </div>
        <div className="recipe-grid">
          <article className="recipe-card">
            <div className="recipe-image">
              <img alt="香煎三文鱼藜麦碗" src="https://images.unsplash.com/photo-1543352634-a1c51d9f1fa7?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=800&h=620" />
              <span>
                高蛋白
              </span>
              <button className="saved" aria-label="取消收藏">
                <svg aria-hidden="true" className width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="m5 12 4 4L19 6" />
                </svg>
              </button>
            </div>
            <div className="recipe-content">
              <h3>
                香煎三文鱼藜麦碗
              </h3>
              <div>
                <span>
                  <svg aria-hidden="true" className width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <circle cx="12" cy="12" r="9" />
                    <path d="M12 7v5l3 2" />
                  </svg>
                   25 分钟
                </span>
                <span>
                  <svg aria-hidden="true" className width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M12 22c4.4 0 7-3.2 7-7.3 0-3.2-2-6.4-5-9.7-.5 3-2 4.2-3 5.5-.7-2-1.8-3.7-3.4-5C6.4 9 5 11.5 5 15c0 4 2.7 7 7 7Z" />
                  </svg>
                   520 千卡
                </span>
                <span>
                  简单
                </span>
              </div>
              <button>
                查看食谱 
                <svg aria-hidden="true" className width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="m9 18 6-6-6-6" />
                </svg>
              </button>
            </div>
          </article>
          <article className="recipe-card">
            <div className="recipe-image">
              <img alt="缤纷地中海蔬菜碗" src="https://images.unsplash.com/photo-1580683750935-cecfc7ea57f0?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=800&h=620" />
              <span>
                低脂
              </span>
              <button className aria-label="收藏食谱">
                <svg aria-hidden="true" className width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M12 5v14M5 12h14" />
                </svg>
              </button>
            </div>
            <div className="recipe-content">
              <h3>
                缤纷地中海蔬菜碗
              </h3>
              <div>
                <span>
                  <svg aria-hidden="true" className width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <circle cx="12" cy="12" r="9" />
                    <path d="M12 7v5l3 2" />
                  </svg>
                   20 分钟
                </span>
                <span>
                  <svg aria-hidden="true" className width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M12 22c4.4 0 7-3.2 7-7.3 0-3.2-2-6.4-5-9.7-.5 3-2 4.2-3 5.5-.7-2-1.8-3.7-3.4-5C6.4 9 5 11.5 5 15c0 4 2.7 7 7 7Z" />
                  </svg>
                   380 千卡
                </span>
                <span>
                  简单
                </span>
              </div>
              <button>
                查看食谱 
                <svg aria-hidden="true" className width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="m9 18 6-6-6-6" />
                </svg>
              </button>
            </div>
          </article>
          <article className="recipe-card">
            <div className="recipe-image">
              <img alt="草莓酸奶燕麦杯" src="https://images.unsplash.com/photo-1629793982045-5f847bd65a61?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=800&h=620" />
              <span>
                早餐
              </span>
              <button className aria-label="收藏食谱">
                <svg aria-hidden="true" className width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M12 5v14M5 12h14" />
                </svg>
              </button>
            </div>
            <div className="recipe-content">
              <h3>
                草莓酸奶燕麦杯
              </h3>
              <div>
                <span>
                  <svg aria-hidden="true" className width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <circle cx="12" cy="12" r="9" />
                    <path d="M12 7v5l3 2" />
                  </svg>
                   10 分钟
                </span>
                <span>
                  <svg aria-hidden="true" className width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M12 22c4.4 0 7-3.2 7-7.3 0-3.2-2-6.4-5-9.7-.5 3-2 4.2-3 5.5-.7-2-1.8-3.7-3.4-5C6.4 9 5 11.5 5 15c0 4 2.7 7 7 7Z" />
                  </svg>
                   320 千卡
                </span>
                <span>
                  简单
                </span>
              </div>
              <button>
                查看食谱 
                <svg aria-hidden="true" className width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="m9 18 6-6-6-6" />
                </svg>
              </button>
            </div>
          </article>
          <article className="recipe-card">
            <div className="recipe-image">
              <img alt="牛油果鸡蛋能量碗" src="https://images.unsplash.com/photo-1556040221-a1efce785fcc?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=800&h=620" />
              <span>
                高蛋白
              </span>
              <button className aria-label="收藏食谱">
                <svg aria-hidden="true" className width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M12 5v14M5 12h14" />
                </svg>
              </button>
            </div>
            <div className="recipe-content">
              <h3>
                牛油果鸡蛋能量碗
              </h3>
              <div>
                <span>
                  <svg aria-hidden="true" className width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <circle cx="12" cy="12" r="9" />
                    <path d="M12 7v5l3 2" />
                  </svg>
                   18 分钟
                </span>
                <span>
                  <svg aria-hidden="true" className width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M12 22c4.4 0 7-3.2 7-7.3 0-3.2-2-6.4-5-9.7-.5 3-2 4.2-3 5.5-.7-2-1.8-3.7-3.4-5C6.4 9 5 11.5 5 15c0 4 2.7 7 7 7Z" />
                  </svg>
                   460 千卡
                </span>
                <span>
                  简单
                </span>
              </div>
              <button>
                查看食谱 
                <svg aria-hidden="true" className width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="m9 18 6-6-6-6" />
                </svg>
              </button>
            </div>
          </article>
          <article className="recipe-card">
            <div className="recipe-image">
              <img alt="日式时蔬糙米饭" src="https://images.unsplash.com/photo-1672501713435-2ee86a073e9e?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=800&h=620" />
              <span>
                素食
              </span>
              <button className aria-label="收藏食谱">
                <svg aria-hidden="true" className width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M12 5v14M5 12h14" />
                </svg>
              </button>
            </div>
            <div className="recipe-content">
              <h3>
                日式时蔬糙米饭
              </h3>
              <div>
                <span>
                  <svg aria-hidden="true" className width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <circle cx="12" cy="12" r="9" />
                    <path d="M12 7v5l3 2" />
                  </svg>
                   30 分钟
                </span>
                <span>
                  <svg aria-hidden="true" className width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M12 22c4.4 0 7-3.2 7-7.3 0-3.2-2-6.4-5-9.7-.5 3-2 4.2-3 5.5-.7-2-1.8-3.7-3.4-5C6.4 9 5 11.5 5 15c0 4 2.7 7 7 7Z" />
                  </svg>
                   430 千卡
                </span>
                <span>
                  适中
                </span>
              </div>
              <button>
                查看食谱 
                <svg aria-hidden="true" className width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="m9 18 6-6-6-6" />
                </svg>
              </button>
            </div>
          </article>
          <article className="recipe-card">
            <div className="recipe-image">
              <img alt="黄瓜柠檬轻食沙拉" src="https://images.unsplash.com/photo-1604259597308-5321e8e4789c?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=800&h=620" />
              <span>
                低脂
              </span>
              <button className aria-label="收藏食谱">
                <svg aria-hidden="true" className width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M12 5v14M5 12h14" />
                </svg>
              </button>
            </div>
            <div className="recipe-content">
              <h3>
                黄瓜柠檬轻食沙拉
              </h3>
              <div>
                <span>
                  <svg aria-hidden="true" className width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <circle cx="12" cy="12" r="9" />
                    <path d="M12 7v5l3 2" />
                  </svg>
                   12 分钟
                </span>
                <span>
                  <svg aria-hidden="true" className width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M12 22c4.4 0 7-3.2 7-7.3 0-3.2-2-6.4-5-9.7-.5 3-2 4.2-3 5.5-.7-2-1.8-3.7-3.4-5C6.4 9 5 11.5 5 15c0 4 2.7 7 7 7Z" />
                  </svg>
                   260 千卡
                </span>
                <span>
                  简单
                </span>
              </div>
              <button>
                查看食谱 
                <svg aria-hidden="true" className width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="m9 18 6-6-6-6" />
                </svg>
              </button>
            </div>
          </article>
        </div>
      </section>
    </main>
  </div>
</div>